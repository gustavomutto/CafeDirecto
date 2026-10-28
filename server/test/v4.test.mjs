// Pruebas v3.2: mensajes de error en el idioma de la app (ES/EN).
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const { toEnglish } = require('../src/lib/i18n.js');

const B=process.env.API_URL||'http://localhost:3999'; let ok=0,fail=0; const check=(c,m)=>{c?ok++:(fail++,console.log('FAIL',m))};
async function api(p,{token,method='GET',body,lang}={}){const h={};if(token)h.Authorization='Bearer '+token;if(lang)h['Accept-Language']=lang;let b;if(body){h['Content-Type']='application/json';b=JSON.stringify(body);}
 const r=await fetch(B+p,{method,headers:h,body:b});const t=await r.text();let j;try{j=JSON.parse(t)}catch{j=t};return{s:r.status,j}}
const rnd=Math.random().toString(36).slice(2,7);

// 1) Todo mensaje de error escrito en el código tiene su versión en inglés.
const files=[]; const walk=(d)=>{for(const f of readdirSync(d)){const p=join(d,f);statSync(p).isDirectory()?walk(p):p.endsWith('.js')&&files.push(p);}};
walk(new URL('../src',import.meta.url).pathname);
const RE=/(?:bad|notFound|forbidden|conflict|new HttpError\(\d+,|inRange\([^,]+,[^,]+,[^,]+,|error:)\s*\(?\s*(['`])((?:(?!\1).)+)\1/g;
const missing=[];
for(const f of files){ if(f.endsWith('i18n.js')) continue; const src=readFileSync(f,'utf8'); let m;
  while((m=RE.exec(src))){ const msg=m[2].replace(/\$\{[^}]+\}/g,'5'); if(!/[áéíóúñ]|^[A-ZÁÉÍÓÚ¿¡][a-záéíóúñ]/.test(msg)) continue;
    if(toEnglish(msg)===msg) missing.push(`${f.split('/src/')[1]}: ${msg}`);} }
const weak=`La contraseña debe tener al menos 8 caracteres, con letras y números`;
check(toEnglish(weak)!==weak,'weak password message translated');
check(missing.length===0,'messages without English: '+missing.join(' | '));
check(toEnglish('La oferta mínima es US$ 5.20/lb')==='The minimum bid is US$ 5.20/lb','pattern with price');
check(toEnglish('Mensaje que no existe')==='Mensaje que no existe','unknown message stays');

// 2) La API responde en el idioma que manda la app.
let r=await api('/auth/login',{method:'POST',body:{email:`nadie${rnd}@x.co`,password:'cafe1234'},lang:'en'});
check(r.s===401&&r.j.error==='Wrong email or password','login error in English');
r=await api('/auth/login',{method:'POST',body:{email:`nadie${rnd}@x.co`,password:'cafe1234'},lang:'es'});
check(r.s===401&&r.j.error==='Correo o contraseña incorrectos','login error in Spanish');
r=await api('/no-existe',{lang:'en-US,en;q=0.9'}); check(r.s===404&&r.j.error==='Route not found','404 in English');
r=await api('/auth/register',{method:'POST',body:{email:`w${rnd}@x.co`,password:'123',role:'buyer',name:'W'},lang:'en'});
check(r.s===400&&r.j.error.startsWith('The password must have at least 8'),'weak password in English');
r=await api('/me',{lang:'en'}); check(r.s===401&&r.j.error==='Please log in','auth required in English');

// 3) Sin cabecera (versiones viejas de la app) se usa el idioma guardado del usuario.
const reg=await api('/auth/register',{method:'POST',body:{email:`en${rnd}@x.co`,password:'cafe1234',role:'buyer',name:'En',lang:'en'}});
const tok=reg.j.token;
r=await api('/me',{token:tok,method:'PUT',body:{lang:'en'}}); check(r.s===200&&r.j.user.lang==='en','user switches to English');
r=await api('/lots',{token:tok,method:'POST',body:{variety:'Caturra',process:'lavado',sacks:1,sca:86,priceLb:5}});
check(r.s===403&&r.j.error==='Only farmers can publish lots','old app: English from user language');
r=await api('/me',{token:tok,method:'PUT',body:{lang:'es'}}); check(r.s===200&&r.j.user.lang==='es','user switches back to Spanish');
r=await api('/lots',{token:tok,method:'POST',body:{variety:'Caturra',process:'lavado',sacks:1,sca:86,priceLb:5}});
check(r.j.error==='Solo los caficultores publican lotes','old app: Spanish from user language');

console.log('ok',ok,'fail',fail); process.exitCode = fail ? 1 : 0;
