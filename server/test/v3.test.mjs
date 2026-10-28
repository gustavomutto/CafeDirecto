// Pruebas de la auditoría v3: contraseñas, fotos privadas, validaciones, reglas de entrega y cabeceras.
const B=process.env.API_URL||'http://localhost:3999'; let ok=0,fail=0; const check=(c,m)=>{c?ok++:(fail++,console.log('FAIL',m))};
async function api(p,{token,method='GET',body,form}={}){const h={};if(token)h.Authorization='Bearer '+token;let b;if(form)b=form;else if(body){h['Content-Type']='application/json';b=JSON.stringify(body);}
 const r=await fetch(B+p,{method,headers:h,body:b});const t=await r.text();let j;try{j=JSON.parse(t)}catch{j=t};return{s:r.status,j,h:r.headers}}
const rnd=Math.random().toString(36).slice(2,7);
const reg=async(role,name,extra={})=>{const r=await api('/auth/register',{method:'POST',body:{email:`${name}${rnd}@x.co`,password:'cafe1234',role,name,...extra}});return {t:r.j.token,id:r.j.user?.id,s:r.s}};
const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==','base64');
const upload=async(t,bytes,name='a.png',type='image/png')=>{const fd=new FormData();fd.append('file',new Blob([bytes],{type}),name);return api('/images',{token:t,method:'POST',form:fd})};

// Contraseñas: 8+ caracteres con letras y números
let r=await api('/auth/register',{method:'POST',body:{email:`w${rnd}@x.co`,password:'123456',role:'buyer',name:'W'}}); check(r.s===400,'short password rejected');
r=await api('/auth/register',{method:'POST',body:{email:`w${rnd}@x.co`,password:'abcdefgh',role:'buyer',name:'W'}}); check(r.s===400,'password without digits rejected');
const F=await reg('farmer','fa',{farmName:'Finca',region:'Huila'}); const Bu=await reg('buyer','bu',{company:'Co'}); const O=await reg('buyer','ot');
check(F.s===201&&Bu.s===201,'valid registrations');

// Cabeceras de seguridad y X-Request-Id
r=await api('/'); check(r.h.get('x-content-type-options')==='nosniff'&&r.h.get('x-frame-options')==='DENY'&&!r.h.get('x-powered-by'),'security headers');
check(!!r.h.get('x-request-id'),'request id');

// Fotos: tipo real (no basta el nombre) y dueño
r=await upload(F.t,Buffer.from('esto no es una imagen, es texto plano para probar'),'falsa.png','image/png'); check(r.s===400,'fake image rejected');
r=await upload(F.t,png); check(r.s===201,'real png accepted'); const fImg=r.j.id;
r=await upload(Bu.t,png); const bImg=r.j.id;
r=await api('/me',{token:F.t,method:'PUT',body:{photoId:bImg}}); check(r.s===400,'cannot use someone else photo on profile');
r=await api('/lots',{token:F.t,method:'POST',body:{variety:'Caturra',process:'lavado',sacks:10,sca:86,priceLb:5,photoId:bImg}}); check(r.s===400,'cannot use someone else photo on lot');

// Validaciones con rango
r=await api('/lots',{token:F.t,method:'POST',body:{variety:'Caturra',process:'lavado',sacks:10,sca:86,priceLb:5000}}); check(r.s===400,'absurd price rejected');
r=await api('/lots',{token:F.t,method:'POST',body:{variety:'Caturra',process:'lavado',sacks:10,sca:120,priceLb:5}}); check(r.s===400,'sca over 100 rejected');
r=await api('/lots',{token:F.t,method:'POST',body:{variety:'Caturra',process:'lavado',sacks:-5,sca:86,priceLb:5}}); check(r.s===400,'negative sacks rejected');
r=await api('/me/profile',{token:F.t,method:'PUT',body:{name:'Finca',altitude:99999}}); check(r.s===400,'absurd altitude rejected');
r=await api('/lots',{token:F.t,method:'POST',body:{name:'Lote A',variety:'Caturra',process:'lavado',sacks:10,sca:86,priceLb:5,photoId:fImg}}); check(r.s===201,'valid lot'); const lid=r.j.id;

// Acuerdo: despacho lo marca el caficultor, entrega el comprador
r=await api('/conversations',{token:Bu.t,method:'POST',body:{userId:F.id,lotId:lid}}); const cid=r.j.id;
r=await api(`/conversations/${cid}/messages`,{token:Bu.t,method:'POST',body:{type:'photo',photoId:fImg}}); check(r.s===400,'cannot send someone else photo in chat');
r=await api(`/conversations/${cid}/quotes`,{token:F.t,method:'POST',body:{lotId:lid,priceLb:500,sacks:2}}); check(r.s===400,'absurd quote rejected');
r=await api(`/conversations/${cid}/quotes`,{token:F.t,method:'POST',body:{lotId:lid,priceLb:5.5,sacks:2}}); const q=r.j.id;
await api(`/messages/${q}/quote`,{token:Bu.t,method:'POST',body:{action:'accept'}});
await api(`/messages/${q}/quote`,{token:F.t,method:'POST',body:{action:'confirm'}});
const aid=(await api('/agreements',{token:F.t})).j[0].id;
r=await api(`/agreements/${aid}/advance`,{token:Bu.t,method:'POST'}); check(r.s===403,'buyer cannot mark shipped');
r=await api(`/agreements/${aid}/advance`,{token:F.t,method:'POST'}); check(r.s===200&&r.j.status===2,'farmer marks shipped');
r=await api(`/agreements/${aid}/advance`,{token:F.t,method:'POST'}); check(r.s===403,'farmer cannot mark delivered');
r=await api(`/agreements/${aid}/advance`,{token:O.t,method:'POST'}); check(r.s===403,'stranger cannot touch agreement');
r=await api(`/agreements/${aid}/advance`,{token:Bu.t,method:'POST'}); check(r.s===200&&r.j.status===3,'buyer marks delivered');

// /unread trae el id del aviso más reciente
r=await api('/unread',{token:F.t}); check(typeof r.j.latestNotificationId==='number'&&r.j.latestNotificationId>0,'unread latest id');

// Token con algoritmo distinto (none) no entra
const fake=Buffer.from(JSON.stringify({alg:'none',typ:'JWT'})).toString('base64url')+'.'+Buffer.from(JSON.stringify({uid:F.id,v:0})).toString('base64url')+'.';
r=await api('/me',{token:fake}); check(r.s===401,'alg none rejected');

// Página de privacidad pública (la pide Google Play)
r=await api('/privacy'); check(r.s===200&&String(r.j).includes('CaféDirecto'),'privacy page');

console.log('ok',ok,'fail',fail); process.exitCode = fail ? 1 : 0;
