const B=process.env.API_URL||'http://localhost:3999';
let ok=0, fail=0;
const check=(c,m)=>{ if(c){ok++;} else {fail++; console.log('FAIL',m);} };
async function api(path,{token,method='GET',body,form}={}){
  const headers={}; if(token) headers.Authorization='Bearer '+token;
  let b; if(form){b=form;} else if(body){headers['Content-Type']='application/json'; b=JSON.stringify(body);}
  const r=await fetch(B+path,{method,headers,body:b}); const t=await r.text(); let j; try{j=JSON.parse(t)}catch{j=t}
  return {s:r.status,j};
}
const rnd=Math.random().toString(36).slice(2,7);
let r=await api('/auth/register',{method:'POST',body:{email:`luz${rnd}@x.co`,password:'cafe1234',role:'farmer',name:'Luz Marina',farmName:'La Esperanza',region:'Huila'}});
check(r.s===201,'reg farmer '+JSON.stringify(r.j)); const F=r.j.token, fid=r.j.user.id;
r=await api('/auth/register',{method:'POST',body:{email:`lena${rnd}@x.de`,password:'cafe1234',role:'buyer',name:'Lena',company:'Nordlicht'}});
check(r.s===201 && r.j.user.lang==='en','reg buyer'); const Bt=r.j.token, bid=r.j.user.id;
r=await api('/auth/register',{method:'POST',body:{email:`lena${rnd}@x.de`,password:'cafe1234',role:'buyer',name:'X'}}); check(r.s===409,'dup email');
r=await api('/auth/login',{method:'POST',body:{email:`luz${rnd}@x.co`,password:'bad'}}); check(r.s===401,'bad login');
r=await api('/auth/login',{method:'POST',body:{email:`LUZ${rnd}@x.co`,password:'cafe1234'}}); check(r.s===200,'login');
// image
const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==','base64');
const fd=new FormData(); fd.append('file', new Blob([png],{type:'image/png'}),'a.png');
r=await api('/images',{token:F,method:'POST',form:fd}); check(r.s===201,'upload '+JSON.stringify(r.j)); const img=r.j.id;
const imgUrl=r.j.url; check(/^\/images\/\d+\?s=[\w-]{16}$/.test(imgUrl),'signed url '+imgUrl);
let g=await fetch(B+imgUrl); check(g.status===200 && g.headers.get('content-type')==='image/png','get img');
g=await fetch(B+'/images/'+img); check(g.status===404,'unsigned image hidden');
g=await fetch(B+imgUrl.replace(/s=.*/,'s=AAAAAAAAAAAAAAAA')); check(g.status===404,'bad signature hidden');
r=await api('/me',{token:F,method:'PUT',body:{photoId:img,phone:'+57 300'}}); check(r.j.user.photo===imgUrl,'me photo');
r=await api('/me/profile',{token:F,method:'PUT',body:{name:'La Esperanza',region:'Huila',municipality:'Pitalito',altitude:1750,hectares:6,varieties:['Caturra'],processes:['honey'],sca:87.5,notes:['panela'],since:1998,story:'Somos tres generaciones',quote:'Hola',certifications:'DOP Huila\nFNC',coverId:img,gallery:[img]}});
check(r.s===200 && r.j.profile.story.es==='Somos tres generaciones' && r.j.profile.certifications.length===2,'farm profile '+JSON.stringify(r.j).slice(0,300));
r=await api('/me/profile',{token:Bt,method:'PUT',body:{company:'Nordlicht',city:'Berlin',country:'Germany',about:'We roast',looking:'Honey lots'}});
check(r.j.profile.about.en==='We roast','buyer profile');
// lots
r=await api('/lots',{token:Bt,method:'POST',body:{variety:'Caturra',process:'honey',sacks:28,sca:87.5,priceLb:5.9}}); check(r.s===403,'buyer cannot post lot');
r=await api('/lots',{token:F,method:'POST',body:{name:'Mandarina',variety:'Pink Bourbon',process:'honey',sacks:28,sca:87.5,priceLb:5.9,notes:['panela'],photoId:img}});
check(r.s===201 && r.j.farm.region==='Huila' && r.j.isNew,'post lot '+JSON.stringify(r.j)); const lid=r.j.id;
r=await api('/lots?region=Huila&minSca=85&q=mandar',{token:Bt}); check(r.j.some(l=>l.id===lid),'filter lots');
r=await api('/lots?region=Cauca',{token:Bt}); check(!r.j.some(l=>l.id===lid),'filter out');
r=await api('/lots/'+lid,{token:Bt}); check(r.j.certifications.length===2,'lot detail');
r=await api('/users/'+fid,{token:Bt}); check(r.j.lots.length===1 && r.j.profile.name==='La Esperanza','user page');
// chat
r=await api('/conversations',{token:Bt,method:'POST',body:{userId:fid,lotId:lid}}); check(r.s===201,'conv '+JSON.stringify(r.j)); const cid=r.j.id;
r=await api('/conversations',{token:Bt,method:'POST',body:{userId:bid}}); check(r.s===400,'same role conv');
r=await api(`/conversations/${cid}/messages`,{token:Bt,method:'POST',body:{text:'Hi! I love your coffee'}}); check(r.s===201 && r.j.from==='buyer' && r.j.lang==='en','send msg');
r=await api('/unread',{token:F}); check(r.j.unread===2,'unread farmer '+JSON.stringify(r.j));
r=await api('/conversations',{token:F}); check(r.j[0].unread===2 && r.j[0].other.name==='Lena','conv list farmer '+JSON.stringify(r.j[0]).slice(0,200));
r=await api(`/conversations/${cid}/read`,{token:F,method:'POST',body:{}}); r=await api('/unread',{token:F}); check(r.j.unread===0,'read');
r=await api(`/conversations/${cid}/messages`,{token:F,method:'POST',body:{type:'photo',photoId:img,text:'Secado'}}); check(r.j.type==='photo','photo msg');
// quote flow
r=await api(`/conversations/${cid}/quotes`,{token:F,method:'POST',body:{lotId:lid,priceLb:5.9,sacks:20,incoterm:'FOB Buenaventura'}}); check(r.s===201,'quote '+JSON.stringify(r.j)); const q1=r.j.id;
r=await api(`/messages/${q1}/quote`,{token:F,method:'POST',body:{action:'accept'}}); check(r.s===400,'own accept blocked');
r=await api(`/messages/${q1}/quote`,{token:Bt,method:'POST',body:{action:'counter',priceLb:5.65,sacks:20}}); check(r.s===200,'counter '+JSON.stringify(r.j)); const q2=r.j.messages[0].id;
r=await api(`/messages/${q2}/quote`,{token:F,method:'POST',body:{action:'accept'}}); check(r.s===200,'accept');
r=await api(`/messages/${q2}/quote`,{token:F,method:'POST',body:{action:'confirm'}}); check(r.s===400,'self confirm blocked');
r=await api(`/messages/${q2}/quote`,{token:Bt,method:'POST',body:{action:'confirm'}}); check(r.s===200 && r.j.messages[0].type==='agreement','confirm '+JSON.stringify(r.j)); const aid=r.j.messages[0].agreementId;
r=await api('/lots/'+lid,{token:Bt}); check(r.j.sacks===8,'sacks decreased');
r=await api(`/conversations/${cid}/messages?after=0`,{token:Bt}); const qs=r.j.filter(m=>m.type==='quote'); check(qs[0].quote.status==='superseded' && qs[1].quote.status==='agreed' && qs[1].quote.history.length===2,'quote statuses');
r=await api('/agreements',{token:F}); check(r.j[0].code.startsWith('CD-') && r.j[0].buyer.company==='Nordlicht','agreements '+JSON.stringify(r.j[0]).slice(0,200));
r=await api(`/agreements/${aid}/rate`,{token:Bt,method:'POST',body:{stars:5}}); check(r.s===400,'rate before delivered');
await api(`/agreements/${aid}/advance`,{token:F,method:'POST'}); r=await api(`/agreements/${aid}/advance`,{token:Bt,method:'POST'}); check(r.j.status===3 && r.j.history[3]>0,'advance');
r=await api(`/agreements/${aid}/rate`,{token:Bt,method:'POST',body:{stars:5,tags:['quality'],comment:'Great cup'}}); check(r.s===201 && r.j.ratings.byBuyer.stars===5,'rate');
r=await api(`/agreements/${aid}/rate`,{token:Bt,method:'POST',body:{stars:4}}); check(r.s===409,'double rate');
r=await api('/users/'+fid,{token:Bt}); check(r.j.profile.rating.count===1 && r.j.profile.reviews[0].by==='Nordlicht','farm rating '+JSON.stringify(r.j.profile.rating));
r=await api('/me',{}); check(r.s===401,'no token');
console.log('ok',ok,'fail',fail); process.exitCode = fail ? 1 : 0;
