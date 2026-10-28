const B=process.env.API_URL||'http://localhost:3999'; let ok=0,fail=0; const check=(c,m)=>{c?ok++:(fail++,console.log('FAIL',m))};
async function api(p,{token,method='GET',body}={}){const h={};if(token)h.Authorization='Bearer '+token;if(body)h['Content-Type']='application/json';
 const r=await fetch(B+p,{method,headers:h,body:body&&JSON.stringify(body)});const t=await r.text();let j;try{j=JSON.parse(t)}catch{j=t};return{s:r.status,j}}
const rnd=Math.random().toString(36).slice(2,7);
const reg=async(role,name,extra={})=>{const r=await api('/auth/register',{method:'POST',body:{email:`${name}${rnd}@x.co`,password:'cafe1234',role,name,...extra}});return {t:r.j.token,id:r.j.user.id}};
const F=await reg('farmer','luz',{farmName:'La Esperanza',region:'Huila'});
const B1=await reg('buyer','lena',{company:'Nordlicht',country:'Alemania'});
const B2=await reg('buyer','kenji',{company:'Kissa',country:'Japón',lang:'en'});
let r=await api('/lots',{token:F.t,method:'POST',body:{name:'Mandarina',variety:'Pink Bourbon',process:'honey',sacks:30,sca:88,priceLb:5}}); const lid=r.j.id;
// interés
r=await api(`/lots/${lid}`,{token:B1.t}); check(r.s===200,'buyer views lot');
r=await api(`/lots/${lid}`,{token:B1.t}); // segunda vista: no duplica aviso
r=await api('/notifications',{token:F.t}); check(r.j.items.length===1 && r.j.items[0].type==='lot_interest' && r.j.unread===1,'one interest notif '+JSON.stringify(r.j).slice(0,300));
check(r.j.items[0].title.es.includes('lena') && r.j.items[0].data.lotId===lid,'notif content '+JSON.stringify(r.j.items[0]));
r=await api(`/lots/${lid}`,{token:F.t}); check(r.j.interest===1,'owner sees interest count');
r=await api(`/lots/${lid}/interest`,{token:F.t}); check(r.j.length===1&&r.j[0].views===2&&r.j[0].company==='Nordlicht','interest list '+JSON.stringify(r.j));
r=await api(`/lots/${lid}/interest`,{token:B1.t}); check(r.s===403,'buyer cannot see interest');
r=await api('/unread',{token:F.t}); check(r.j.notifications===1,'unread includes notifs');
r=await api('/notifications/unread',{token:F.t}); check(r.j.unread===1&&r.j.latestId>0,'unread endpoint');
const latest=r.j.latestId;
// subasta
r=await api(`/lots/${lid}/auction`,{token:B1.t,method:'POST',body:{}}); check(r.s===403,'buyer cannot open auction');
r=await api(`/lots/${lid}/auction`,{token:F.t,method:'POST',body:{basePriceLb:5.5,minIncrementLb:0.1,sacks:20,durationHours:24}}); check(r.s===201&&r.j.phase==='live'&&r.j.minNext===5.5,'open auction '+JSON.stringify(r.j).slice(0,300)); const aid=r.j.id;
r=await api(`/lots/${lid}/auction`,{token:F.t,method:'POST',body:{}}); check(r.s===409,'only one open auction');
r=await api('/notifications',{token:B1.t}); check(r.j.items.some(n=>n.type==='auction_opened'),'interested buyer notified of auction');
r=await api(`/lots?auction=1`,{token:B2.t}); check(r.j.some(l=>l.id===lid&&l.auction&&l.auction.phase==='live'),'lots filter auction');
r=await api('/auctions',{token:B2.t}); check(r.j.some(a=>a.id===aid),'list live auctions');
r=await api(`/auctions/${aid}/bids`,{token:B1.t,method:'POST',body:{priceLb:5.4}}); check(r.s===400,'below base rejected');
r=await api(`/auctions/${aid}/bids`,{token:F.t,method:'POST',body:{priceLb:6}}); check(r.s===403,'farmer cannot bid');
r=await api(`/auctions/${aid}/bids`,{token:B1.t,method:'POST',body:{priceLb:5.5}}); check(r.s===201&&r.j.leading&&r.j.minNext===5.6,'first bid '+JSON.stringify(r.j).slice(0,200));
r=await api(`/auctions/${aid}/bids`,{token:B2.t,method:'POST',body:{priceLb:5.55}}); check(r.s===400,'increment enforced');
r=await api(`/auctions/${aid}/bids`,{token:B2.t,method:'POST',body:{priceLb:5.8}}); check(r.s===201&&r.j.leading&&r.j.highest===5.8,'second bid');
check(r.j.bids.find(b=>!b.mine).bidder===null && r.j.bids.find(b=>!b.mine).alias===1,'other bidder anonymized for buyer');
r=await api('/notifications',{token:B1.t}); check(r.j.items.some(n=>n.type==='bid_outbid'),'outbid notified');
r=await api('/notifications',{token:F.t}); check(r.j.items.filter(n=>n.type==='bid_new').length===2,'farmer notified of bids');
r=await api(`/notifications?after=${latest}`,{token:F.t}); check(r.j.items.length===2&&r.j.items[0].id>latest,'after filter');
r=await api(`/auctions/${aid}`,{token:F.t}); check(r.j.bids.every(b=>b.bidder&&b.bidder.name),'farmer sees bidders'); const bidB1=r.j.bids.find(b=>b.bidder.id===B1.id).id;
r=await api(`/lots/${lid}`,{token:F.t,method:'DELETE'}); check(r.s===400,'cannot delete lot with open auction');
// adjudica a B1 (no necesariamente el mayor)
r=await api(`/auctions/${aid}/award`,{token:B1.t,method:'POST',body:{bidId:bidB1}}); check(r.s===403,'buyer cannot award');
r=await api(`/auctions/${aid}/award`,{token:F.t,method:'POST',body:{bidId:bidB1}}); check(r.s===200&&r.j.auction.phase==='awarded'&&r.j.agreementId,'award '+JSON.stringify(r.j).slice(0,300));
const agId=r.j.agreementId;
r=await api(`/agreements/${agId}`,{token:B1.t}); check(r.s===200&&r.j.priceLb===5.5&&r.j.sacks===20&&r.j.conversationId,'agreement created for winner');
r=await api(`/lots/${lid}`,{token:F.t}); check(r.j.sacks===10&&r.j.auction===null,'sacks decremented, auction closed');
r=await api('/notifications',{token:B1.t}); check(r.j.items.some(n=>n.type==='auction_won'&&n.data.agreementId===agId),'winner notified');
r=await api('/notifications',{token:B2.t}); check(r.j.items.some(n=>n.type==='auction_lost'),'loser notified');
r=await api(`/auctions/${aid}/bids`,{token:B2.t,method:'POST',body:{priceLb:9}}); check(r.s===400,'no bids after award');
r=await api('/conversations',{token:B1.t}); check(r.j.some(c=>c.lot&&c.lot.id===lid),'conversation with winner');
r=await api('/auctions?mine=1',{token:B2.t}); check(r.j.length===1&&r.j[0].myBest===5.8,'buyer my auctions');
r=await api('/auctions?mine=1',{token:F.t}); check(r.j.length===1,'farmer my auctions');
// cancelar
r=await api(`/lots/${lid}/auction`,{token:F.t,method:'POST',body:{basePriceLb:5,sacks:5,durationHours:1}}); const aid2=r.j.id; check(r.s===201,'reopen');
await api(`/auctions/${aid2}/bids`,{token:B2.t,method:'POST',body:{priceLb:5}});
r=await api(`/auctions/${aid2}/cancel`,{token:F.t,method:'POST'}); check(r.s===200&&r.j.phase==='cancelled','cancel');
r=await api('/notifications',{token:B2.t}); check(r.j.items.some(n=>n.type==='auction_cancelled'),'cancel notified');
// marcar leídas
r=await api('/notifications/read',{token:F.t,method:'POST',body:{all:true}}); check(r.j.unread===0,'read all');
r=await api('/notifications',{token:B1.t}); const one1=r.j.items[0].id; r=await api('/notifications/read',{token:B1.t,method:'POST',body:{ids:[one1]}}); check(r.j.ok,'read ids');
// cotización notifica
r=await api('/conversations',{token:F.t}); const cid=r.j[0].id;
r=await api(`/conversations/${cid}/quotes`,{token:F.t,method:'POST',body:{lotId:lid,priceLb:6,sacks:2}}); check(r.s===201,'quote');
r=await api('/notifications',{token:B1.t}); check(r.j.items.some(n=>n.type==='quote_new'),'quote notif');
// mercado (en el sandbox no hay internet: debe responder 200 igual)
r=await api('/market/coffee'); check(r.s===200&&'internal' in r.j&&'constants' in r.j,'market endpoint '+JSON.stringify(r.j).slice(0,300));
console.log('ok',ok,'fail',fail); process.exitCode = fail ? 1 : 0;
