function natural(v,name){if(!Number.isSafeInteger(v)||v<0)throw new RangeError(`${name}: inteiro não negativo obrigatório`);return v}

function checked(n){if(n<0n||n>BigInt(Number.MAX_SAFE_INTEGER))throw new RangeError("Valor fora do intervalo");return Number(n)}

function sum(values){return checked(values.reduce((a,v)=>a+BigInt(natural(v,"valor")),0n))}

function rounded(n,d){return checked((n+d/2n)/d)}

function orderTotal({channel,items,orderDiscount=0,serviceAccepted=true,deliveryFee=0}){
 if(!["mesa","balcao","retirada","delivery"].includes(channel))throw new RangeError("Canal inválido");
 if(!Array.isArray(items)||typeof serviceAccepted!=="boolean")throw new TypeError("Pedido inválido");
 natural(orderDiscount,"desconto");natural(deliveryFee,"entrega");
 if(channel!=="delivery"&&deliveryFee!==0)throw new RangeError("Taxa de entrega inválida para canal");
 const lines=items.map(({unitPrice,quantity,discount=0,serviceEligible=true})=>{
   natural(unitPrice,"preço");natural(quantity,"quantidade");natural(discount,"desconto");
   if(quantity===0||typeof serviceEligible!=="boolean")throw new RangeError("Item inválido");
   const gross=checked(BigInt(unitPrice)*BigInt(quantity));if(discount>gross)throw new RangeError("Desconto excede item");
   return {gross,net:gross-discount,serviceEligible};
 });
 const gross=sum(lines.map(x=>x.gross)), beforeOrderDiscount=sum(lines.map(x=>x.net));
 if(orderDiscount>beforeOrderDiscount)throw new RangeError("Desconto excede subtotal");
 const subtotal=beforeOrderDiscount-orderDiscount;
 const eligible=sum(lines.filter(x=>x.serviceEligible).map(x=>x.net));
 const eligibleDiscount=beforeOrderDiscount===0?0:rounded(BigInt(orderDiscount)*BigInt(eligible),BigInt(beforeOrderDiscount));
 const serviceBase=eligible-eligibleDiscount;
 const serviceCharge=channel==="mesa"&&serviceAccepted?rounded(BigInt(serviceBase),10n):0;
 return {gross,discount:gross-subtotal,subtotal,serviceBase,serviceCharge,deliveryFee,total:sum([subtotal,serviceCharge,deliveryFee])};
}

function cashPayment({total,previousPaid=0,electronic=0,cashReceived=0}){
 natural(total,"total");natural(previousPaid,"pagamentos anteriores");natural(electronic,"eletrônico");natural(cashReceived,"dinheiro recebido");
 if(previousPaid>total||electronic>total-previousPaid)throw new RangeError("Pagamento eletrônico excede saldo");
 const due=total-previousPaid-electronic,cashApplied=Math.min(cashReceived,due);
 return {cashApplied,change:cashReceived-cashApplied,remaining:due-cashApplied,paid:sum([previousPaid,electronic,cashApplied])};
}

function equalSplit(total,count){natural(total,"total");natural(count,"pessoas");if(count<1||count>10000)throw new RangeError("Quantidade de pessoas inválida");const base=Math.floor(total/count),remainder=total%count;return Array.from({length:count},(_,i)=>base+(i<remainder?1:0))}

function reconcileCash({opening,cashReceipts,additions=0,withdrawals=0,cashRefunds=0,counted}){
 const incoming=sum([opening,cashReceipts,additions]),outgoing=sum([withdrawals,cashRefunds]);natural(counted,"contado");
 const expected=incoming-outgoing,delta=BigInt(counted)-BigInt(expected);
 if(delta>BigInt(Number.MAX_SAFE_INTEGER)||delta< -BigInt(Number.MAX_SAFE_INTEGER))throw new RangeError("Diferença fora do intervalo");
 return {expected,difference:Number(delta),status:delta===0n?"correto":delta>0n?"sobra":"falta"};
}

function packageUnits(quantity,unitsPerPackage){natural(quantity,"quantidade");natural(unitsPerPackage,"unidades por pacote");if(unitsPerPackage===0)throw new RangeError("Pacote inválido");return checked(BigInt(quantity)*BigInt(unitsPerPackage))}

export {orderTotal,cashPayment,equalSplit,reconcileCash,packageUnits};
