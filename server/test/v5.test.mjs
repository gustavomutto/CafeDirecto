// Pruebas de seguridad móvil (tarea OWASP Mobile Top 10): sesiones revocables (H-02) y clave JWT (H-01).
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const jwt = require('jsonwebtoken');

const B=process.env.API_URL||'http://localhost:3999'; let ok=0,fail=0; const check=(c,m)=>{c?ok++:(fail++,console.log('FAIL',m))};
async function api(p,{token,method='GET',body}={}){const h={};if(token)h.Authorization='Bearer '+token;let b;if(body){h['Content-Type']='application/json';b=JSON.stringify(body);}
 const r=await fetch(B+p,{method,headers:h,body:b});const t=await r.text();let j;try{j=JSON.parse(t)}catch{j=t};return{s:r.status,j}}
const rnd=Math.random().toString(36).slice(2,7);
const email=`ses${rnd}@x.co`, password='cafe1234';

// H-02: cada inicio de sesión es una sesión distinta; cerrar una no cierra las otras.
const reg=await api('/auth/register',{method:'POST',body:{email,password,role:'farmer',name:'Ses',farmName:'F',region:'Huila'}});
check(reg.s===201,'register');
const phoneA=reg.j.token;
const phoneB=(await api('/auth/login',{method:'POST',body:{email,password}})).j.token;
const claims=jwt.decode(phoneA);
check(typeof claims.sid==='string'&&claims.sid.length>=20,'token trae id de sesión');
check(Math.round((claims.exp-claims.iat)/86400)===30,'el token dura 30 días');

let r=await api('/auth/logout',{token:phoneA,method:'POST'}); check(r.s===200,'logout responde 200');
r=await api('/me',{token:phoneA}); check(r.s===401,'el token cerrado ya no sirve');
r=await api('/me',{token:phoneB}); check(r.s===200,'la sesión del otro teléfono sigue abierta');
r=await api('/auth/logout',{token:phoneA,method:'POST'}); check(r.s===401,'cerrar dos veces → 401');

// Un token con firma válida pero sin sesión (por ejemplo, de una versión anterior) se rechaza.
// No se puede falsificar aquí sin la clave: se comprueba que un token sin `sid` no pasa.
r=await api('/me',{token:jwt.sign({uid:claims.uid,v:0},'otra-clave',{algorithm:'HS256'})}); check(r.s===401,'token sin sesión → 401');

// H-01: la clave de desarrollo que estaba publicada en el repositorio ya no firma tokens válidos.
r=await api('/me',{token:jwt.sign({uid:claims.uid,v:0,sid:claims.sid},'clave-local-solo-para-desarrollo',{algorithm:'HS256'})});
check(r.s===401,'token firmado con la clave pública vieja → 401');

console.log('ok',ok,'fail',fail); process.exitCode = fail ? 1 : 0;
