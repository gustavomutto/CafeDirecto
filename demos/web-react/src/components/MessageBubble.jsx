import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { fmtDuration, fmtTime, fmtUSD, langOf } from '../utils';
import AgreementCard from './AgreementCard';
import Icon from './Icon';
import QuoteCard from './QuoteCard';
import { Img } from './ui';

function TranslationBlock({ msg }) {
  const { lang, tr } = useApp();
  const target = msg.lang === 'es' ? 'en' : 'es';
  let label;
  if (msg.lang === lang) label = target === 'en' ? 'Traducido al inglés' : 'Translated to Spanish';
  else label = msg.lang === 'en' ? 'Traducido del inglés' : 'Translated from Spanish';
  return (
    <div className={`translation ${msg.lang !== lang ? 'for-me' : ''}`}>
      <span className="tr-label">
        <Icon name="translate" size={13} /> {label}
        {!msg.exact && <em> · {tr('aprox.', 'approx.')}</em>}
      </span>
      <p>{msg.translation}</p>
    </div>
  );
}

function LotRef({ lotId }) {
  const { state, lang } = useApp();
  const lot = state.lots.find((l) => l.id === lotId);
  if (!lot) return null;
  return (
    <Link to={`/lot/${lot.id}`} className="msg-lotref">
      <Img src={lot.photo} alt={lot.name} />
      <span>
        <b>{lot.name}</b>
        <small>{lot.variety} · {lot.sca} SCA · {fmtUSD(lot.priceLb, lang)}/lb</small>
      </span>
    </Link>
  );
}

function VoiceNote({ msg }) {
  const { tr } = useApp();
  const [playing, setPlaying] = useState(false);
  // Al llegar, simula unos segundos de "transcribiendo…"
  const [transcribing, setTranscribing] = useState(Date.now() - msg.at < 1800);
  useEffect(() => {
    if (!transcribing) return;
    const t = setTimeout(() => setTranscribing(false), 1800 - (Date.now() - msg.at));
    return () => clearTimeout(t);
  }, [transcribing, msg.at]);

  const bars = [6, 12, 18, 10, 22, 14, 8, 16, 24, 12, 6, 14, 20, 10, 16, 8, 12, 18, 6, 10];
  return (
    <div className="voice">
      <div className="voice-player">
        <button className="voice-play" onClick={() => setPlaying((p) => !p)} aria-label="Play">
          <Icon name={playing ? 'pause' : 'play'} size={18} fill="currentColor" stroke={0} />
        </button>
        <div className={`voice-wave ${playing ? 'playing' : ''}`} style={{ '--dur': `${msg.duration}s` }} onAnimationEnd={() => setPlaying(false)}>
          {bars.map((h, i) => <i key={i} style={{ height: h }} />)}
          <span className="voice-progress" />
        </div>
        <span className="voice-dur">{fmtDuration(msg.duration)}</span>
      </div>
      {transcribing ? (
        <div className="transcribing">
          <Icon name="sparkles" size={14} /> {tr('Transcribiendo y traduciendo…', 'Transcribing & translating…')}
        </div>
      ) : (
        <>
          <span className="tr-label"><Icon name="mic" size={13} /> {tr('Transcripción', 'Transcript')} ({msg.lang === 'es' ? tr('español', 'Spanish') : tr('inglés', 'English')})</span>
          <p className="voice-text">{msg.text}</p>
          <TranslationBlock msg={{ ...msg, exact: true }} />
        </>
      )}
    </div>
  );
}

export default function MessageBubble({ msg, handlers }) {
  const { state, role, pick, lang, tr } = useApp();

  if (msg.type === 'system') {
    return (
      <div className="msg-system">
        <span>{pick(msg.text)}</span>
        {msg.status === 'pending' && <Icon name="clock" size={12} />}
      </div>
    );
  }

  if (msg.type === 'agreement') {
    const ag = state.agreements.find((a) => a.id === msg.agreementId);
    if (!ag) return null;
    return (
      <div className="msg-wide">
        <AgreementCard agreement={ag} inChat />
      </div>
    );
  }

  const mine = msg.from === role;
  const footer = (
    <span className="msg-meta">
      {fmtTime(msg.at, lang)}
      {mine && (msg.status === 'pending'
        ? <span className="pending"><Icon name="clock" size={12} /> {tr('Pendiente de envío', 'Pending')}</span>
        : <Icon name="checks" size={14} className="read" />)}
    </span>
  );

  if (msg.type === 'quote') {
    return (
      <div className={`msg-wide ${mine ? 'mine' : 'theirs'}`}>
        <QuoteCard msg={msg} {...handlers} />
        {footer}
      </div>
    );
  }

  return (
    <div className={`msg ${mine ? 'mine' : 'theirs'} type-${msg.type} ${msg.status === 'pending' ? 'is-pending' : ''}`}>
      <div className="bubble">
        {msg.type === 'text' && (
          <>
            <p className={`original ${msg.lang !== lang ? 'foreign' : ''}`}>{msg.text}</p>
            <TranslationBlock msg={msg} />
          </>
        )}
        {msg.type === 'voice' && <VoiceNote msg={msg} />}
        {msg.type === 'photo' && (
          <>
            <Img src={msg.src} alt="" className="msg-photo" fallback="📷" />
            {msg.caption && (
              <div className="photo-caption">
                <p>{msg.caption[langOf(msg.from)]}</p>
                {langOf(msg.from) !== lang && (
                  <span className="tr-label"><Icon name="translate" size={12} /> {msg.caption[lang]}</span>
                )}
              </div>
            )}
          </>
        )}
        {msg.lotRef && <LotRef lotId={msg.lotRef} />}
        {footer}
      </div>
    </div>
  );
}
