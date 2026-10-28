import fs from 'fs';
const B=process.env.API_URL||'http://localhost:3999'; let ok=0,fail=0; const check=(c,m)=>{c?ok++:(fail++,console.log('FAIL',m))};
async function api(p,{token,method='GET',body}={}){const h={};if(token)h.Authorization='Bearer '+token;if(body)h['Content-Type']='application/json';
 const r=await fetch(B+p,{method,headers:h,body:body&&JSON.stringify(body)});const t=await r.text();let j;try{j=JSON.parse(t)}catch{j=t};return{s:r.status,j}}
const rnd=Math.random().toString(36).slice(2,7); const fe=`f${rnd}@x.co`, be=`b${rnd}@x.de`;
let r=await api('/auth/register',{method:'POST',body:{email:fe,password:'123456',role:'farmer',name:'F',farmName:'Finca',region:'Huila'}}); const F=r.j.token;
r=await api('/auth/register',{method:'POST',body:{email:be,password:'123456',role:'buyer',name:'B',company:'Co'}}); const Bt=r.j.token, bid=r.j.user.id;
// forgot/reset
r=await api('/auth/forgot',{method:'POST',body:{email:fe}}); check(r.s===200,'forgot '+JSON.stringify(r.j));
r=await api('/auth/forgot',{method:'POST',body:{email:'nadie@x.co'}}); check(r.s===200,'forgot unknown same reply');
await new Promise(s=>setTimeout(s,300));
const log=fs.readFileSync(process.argv[2],'utf8'); const code=[...log.matchAll(/código de CaféDirecto: (\d{6})/g)].pop()[1];
r=await api('/auth/reset',{method:'POST',body:{email:fe,code:'000000',password:'nueva123'}}); check(r.s===400,'bad code');
r=await api('/auth/reset',{method:'POST',body:{email:fe,code,password:'nueva123'}}); check(r.s===200&&r.j.token,'reset ok');
const F2=r.j.token;
r=await api('/me',{token:F}); check(r.s===401,'old token revoked');
r=await api('/me',{token:F2}); check(r.s===200,'new token works');
r=await api('/auth/login',{method:'POST',body:{email:fe,password:'nueva123'}}); check(r.s===200,'login new pass');
// lot + quote -> agreement -> delivered
r=await api('/lots',{token:F2,method:'POST',body:{name:'Lote',variety:'Caturra',process:'honey',sca:86,sacks:10,priceLb:5}}); check(r.s===201,'lot '+JSON.stringify(r.j)); const lid=r.j.id;
r=await api('/conversations',{token:Bt,method:'POST',body:{userId:r.j.farmer?.id ?? undefined, lotId:lid}});
if(r.s!==201&&r.s!==200){ const me=await api('/me',{token:F2}); r=await api('/conversations',{token:Bt,method:'POST',body:{userId:me.j.user.id,lotId:lid}}); }
const cid=r.j.id; check(!!cid,'conv '+JSON.stringify(r.j).slice(0,200));
r=await api(`/conversations/${cid}/quotes`,{token:F2,method:'POST',body:{lotId:lid,priceLb:5,sacks:2,incoterm:'FOB'}}); check(r.s===201,'quote '+JSON.stringify(r.j).slice(0,200)); const mid=r.j.id;
r=await api(`/messages/${mid}/quote`,{token:Bt,method:'POST',body:{action:'accept'}}); check(r.s<300,'accept '+JSON.stringify(r.j).slice(0,200));
r=await api(`/messages/${mid}/quote`,{token:F2,method:'POST',body:{action:'confirm'}}); check(r.s<300,'confirm '+JSON.stringify(r.j).slice(0,200));
const ags=await api('/agreements',{token:Bt}); const aid=ags.j[0]?.id; check(!!aid,'agreement');
r=await api(`/agreements/${aid}/quality`,{token:Bt,method:'POST',body:{sca:85}}); check(r.s===400,'quality before delivery blocked');
await api(`/agreements/${aid}/advance`,{token:F2,method:'POST'}); await api(`/agreements/${aid}/advance`,{token:Bt,method:'POST'});
r=await api(`/agreements/${aid}/quality`,{token:F2,method:'POST',body:{sca:85}}); check(r.s===403,'farmer cannot quality');
r=await api(`/agreements/${aid}/quality`,{token:Bt,method:'POST',body:{sca:85.5,moisture:11,defects:3,comment:'Muy buen café'}}); check(r.s===201&&r.j.quality?.sca!=null,'quality '+JSON.stringify(r.j).slice(0,200));
r=await api(`/agreements/${aid}/disputes`,{token:F2,method:'POST',body:{reason:'payment',text:'No ha llegado el pago'}}); check(r.s===201&&r.j.disputes.length===1,'dispute');
const did=r.j.disputes[0].id;
r=await api(`/disputes/${did}/comments`,{token:Bt,method:'POST',body:{text:'Ya lo envié'}}); check(r.s===201,'comment');
r=await api(`/disputes/${did}/resolve`,{token:Bt,method:'POST',body:{}}); check(r.s===403,'only opener resolves');
r=await api(`/disputes/${did}/resolve`,{token:F2,method:'POST',body:{}}); check(r.s===200&&r.j.disputes[0].status==='resolved','resolve');
// delete account
r=await api('/me',{token:Bt,method:'DELETE',body:{password:'mal'}}); check(r.s===403,'delete wrong pass');
r=await api('/me',{token:Bt,method:'DELETE',body:{password:'123456'}}); check(r.s===200,'delete '+JSON.stringify(r.j));
r=await api('/me',{token:Bt}); check(r.s===401,'deleted token dead');
r=await api(`/agreements/${aid}`,{token:F2}); check(r.s===200&&r.j.buyer.name==='Cuenta eliminada','agreement kept anonymized '+JSON.stringify(r.j.buyer));
r=await api('/auth/login',{method:'POST',body:{email:be,password:'123456'}}); check(r.s===401,'deleted cannot login');
// user without agreements gets fully deleted
r=await api('/auth/register',{method:'POST',body:{email:`z${rnd}@x.de`,password:'123456',role:'buyer',name:'Z'}});
r=await api('/me',{token:r.j.token,method:'DELETE',body:{password:'123456'}}); check(r.s===200,'delete plain');
// rate limit login
let last; for(let i=0;i<11;i++) last=await api('/auth/login',{method:'POST',body:{email:'rl@x.co',password:'x'}}); check(last.s===429,'ratelimit '+last.s);
console.log('ok',ok,'fail',fail); process.exitCode = fail ? 1 : 0;
