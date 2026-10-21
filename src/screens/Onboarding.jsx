import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Img, Verified } from '../components/ui';
import { PHOTOS } from '../data/photos';

const SLIDES = {
  farmer: [
    { icon: '🌱', title: 'Muestra tu finca al mundo', text: 'Tu historia, tu café y tu puntaje, en español y en inglés.' },
    { icon: '🎙️', title: 'Habla directo con compradores', text: 'Escribe o graba un audio. La app lo traduce.' },
    { icon: '🤝', title: 'Negocia tu precio', text: 'Sin intermediarios. Acuerdos claros y calificaciones.' },
  ],
  buyer: [
    { icon: '🔎', title: 'Discover traceable origins', text: '80+ SCA farms from Huila to the Sierra Nevada, 1–20 ha each.' },
    { icon: '🌐', title: 'Talk directly, in your language', text: 'Every message is translated. Voice notes arrive transcribed.' },
    { icon: '📄', title: 'Close transparent deals', text: 'Quotes, recorded agreements and mutual reputation.' },
  ],
};

export default function Onboarding() {
  const { state, actions, meFarm, meBuyer } = useApp();
  const navigate = useNavigate();
  const [step, setStep] = useState(0); // 0 bienvenida · 1 rol · 2 slides · 3 registro · 4 verificación
  const [role, setRole] = useState(state.role);
  const [slide, setSlide] = useState(0);
  const [form, setForm] = useState({});
  const [verified, setVerified] = useState(false);
  const [code, setCode] = useState('');
  const es = role === 'farmer';
  const T = (a, b) => (es ? a : b);

  const chooseRole = (r) => {
    setRole(r);
    setForm(
      r === 'farmer'
        ? { name: meFarm.producer, phone: '+57 312 456 7890', farmName: meFarm.name, place: 'Pitalito, Huila' }
        : { name: meBuyer.contact, email: 'lena@nordlicht-kaffee.de', company: meBuyer.company, country: 'Germany', type: 'Roaster' },
    );
    setSlide(0);
    setStep(2);
  };

  // Verificación simulada: código SMS (caficultor) o verificación de empresa (comprador)
  useEffect(() => {
    if (step !== 4) return;
    setVerified(false);
    setCode('');
    if (es) {
      const digits = '4821';
      let i = 0;
      const t = setInterval(() => {
        i++;
        setCode(digits.slice(0, i));
        if (i >= 4) {
          clearInterval(t);
          setTimeout(() => setVerified(true), 400);
        }
      }, 380);
      return () => clearInterval(t);
    }
    const t = setTimeout(() => setVerified(true), 2200);
    return () => clearTimeout(t);
  }, [step, es]);

  const finish = () => {
    actions.completeOnboarding(role, form);
    navigate('/home', { replace: true });
  };

  const field = (key, label, props = {}) => (
    <label className="field">
      <span>{label}</span>
      <input value={form[key] || ''} onChange={(e) => setForm({ ...form, [key]: e.target.value })} {...props} />
    </label>
  );

  return (
    <div className={`screen onboarding ob-step-${step}`}>
      {step === 0 && (
        <div className="ob-splash">
          <Img src={PHOTOS.greenHills} className="ob-bg" alt="" />
          <div className="ob-splash-content">
            <div className="ob-logo">☕</div>
            <h1>CaféDirecto</h1>
            <p className="ob-tag-es">Del cafetal a la taza, sin intermediarios.</p>
            <p className="ob-tag-en">From farm to cup, direct.</p>
            <button className="btn btn-light btn-lg btn-block" onClick={() => setStep(1)}>
              Comenzar · Get started <Icon name="chevron" />
            </button>
          </div>
        </div>
      )}

      {step === 1 && (
        <div className="ob-body">
          <h2 className="ob-title">¿Quién eres?<br /><span>Who are you?</span></h2>
          <button className="role-card farmer" onClick={() => chooseRole('farmer')}>
            <span className="role-emoji">👩🏽‍🌾</span>
            <span>
              <b>Soy caficultor</b>
              <small>Quiero vender mi café</small>
            </span>
            <Icon name="chevron" />
          </button>
          <button className="role-card buyer" onClick={() => chooseRole('buyer')}>
            <span className="role-emoji">☕</span>
            <span>
              <b>I'm a coffee buyer</b>
              <small>Roaster, café or importer</small>
            </span>
            <Icon name="chevron" />
          </button>
          <p className="ob-note">Demo: los datos son de ejemplo · sample data only</p>
        </div>
      )}

      {step === 2 && (
        <div className={`ob-body ob-slides role-${role}`}>
          <button className="ob-skip" onClick={() => setStep(3)}>{T('Saltar', 'Skip')}</button>
          <div className="ob-slide" key={slide}>
            <div className="ob-slide-icon">{SLIDES[role][slide].icon}</div>
            <h2>{SLIDES[role][slide].title}</h2>
            <p>{SLIDES[role][slide].text}</p>
          </div>
          <div className="ob-dots">
            {SLIDES[role].map((_, i) => <i key={i} className={i === slide ? 'on' : ''} />)}
          </div>
          <button
            className="btn btn-primary btn-lg btn-block"
            onClick={() => (slide < 2 ? setSlide(slide + 1) : setStep(3))}
          >
            {slide < 2 ? T('Siguiente', 'Next') : T('Crear mi cuenta', 'Create my account')} <Icon name="chevron" />
          </button>
        </div>
      )}

      {step === 3 && (
        <div className="ob-body ob-form">
          <button className="icon-btn ob-back" onClick={() => setStep(1)}><Icon name="back" /></button>
          <h2>{T('Tus datos', 'Your details')}</h2>
          <p className="muted">{T('Ya los llenamos por ti para la demo.', 'Pre-filled for the demo.')}</p>
          {es ? (
            <>
              {field('name', '👤 Tu nombre')}
              {field('phone', '📱 Celular', { inputMode: 'tel' })}
              {field('farmName', '🏡 Nombre de la finca')}
              {field('place', '📍 Municipio y departamento')}
            </>
          ) : (
            <>
              {field('name', 'Full name')}
              {field('email', 'Work email', { type: 'email' })}
              {field('company', 'Company')}
              <div className="field-row">
                {field('country', 'Country')}
                {field('type', 'Buyer type')}
              </div>
            </>
          )}
          <button className="btn btn-primary btn-lg btn-block" onClick={() => setStep(4)}>
            {T('Continuar', 'Continue')} <Icon name="chevron" />
          </button>
        </div>
      )}

      {step === 4 && (
        <div className="ob-body ob-verify">
          {es ? (
            <>
              <div className="ob-slide-icon">📲</div>
              <h2>Te enviamos un código por SMS</h2>
              <p className="muted">{form.phone}</p>
              <div className="code-boxes">
                {[0, 1, 2, 3].map((i) => <span key={i} className={code[i] ? 'filled' : ''}>{code[i] || ''}</span>)}
              </div>
            </>
          ) : (
            <>
              <div className={`verify-circle ${verified ? 'done' : ''}`}>
                {verified ? <Icon name="shield" size={44} /> : <Icon name="sync" size={40} className="spin" />}
              </div>
              <h2>{verified ? 'Company verified' : 'Verifying your company…'}</h2>
              <p className="muted">{form.company} · {form.country}</p>
              {verified && <Verified label="Verified buyer" />}
            </>
          )}
          {verified && (
            <button className="btn btn-primary btn-lg btn-block pop-in" onClick={finish}>
              {T('Entrar a CaféDirecto', 'Enter CaféDirecto')} <Icon name="chevron" />
            </button>
          )}
        </div>
      )}
    </div>
  );
}
