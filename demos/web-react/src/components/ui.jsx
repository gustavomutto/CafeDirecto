import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import Icon from './Icon';
import { useApp } from '../context/AppContext';

/** Imagen con respaldo: si la URL falla, muestra un fondo café con un ícono */
export function Img({ src, alt = '', className = '', fallback = '☕', style }) {
  const [failed, setFailed] = useState(!src);
  if (failed) {
    return (
      <div className={`img-fallback ${className}`} style={style} role="img" aria-label={alt}>
        <span>{fallback}</span>
      </div>
    );
  }
  return <img src={src} alt={alt} className={className} style={style} loading="lazy" onError={() => setFailed(true)} />;
}

export function Avatar({ src, name = '', size = 44, className = '' }) {
  const initials = name.split(' ').map((p) => p[0]).slice(0, 2).join('');
  return (
    <div className={`avatar ${className}`} style={{ width: size, height: size, fontSize: size * 0.38 }}>
      <Img src={src} alt={name} fallback={initials} />
    </div>
  );
}

export function Stars({ value = 0, size = 14, showValue = false, count }) {
  return (
    <span className="stars" aria-label={`${value.toFixed(1)} / 5`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <Icon key={i} name="star" size={size} stroke={1.5} fill={value >= i - 0.25 ? 'currentColor' : 'none'} />
      ))}
      {showValue && <b>{value.toFixed(1)}</b>}
      {count != null && <small>({count})</small>}
    </span>
  );
}

export function ScoreBadge({ sca, large = false }) {
  return (
    <span className={`score-badge ${large ? 'large' : ''}`}>
      <b>{Number(sca).toFixed(sca % 1 ? 1 : 0)}</b>
      <small>SCA</small>
    </span>
  );
}

export function Verified({ label }) {
  return (
    <span className="verified">
      <Icon name="shield" size={14} />
      {label}
    </span>
  );
}

/** Hoja inferior (bottom sheet) dentro del celular */
export function Sheet({ open, onClose, title, children, footer }) {
  if (!open) return null;
  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-label={title}>
        <div className="sheet-handle" />
        <div className="sheet-head">
          <h3>{title}</h3>
          <button className="icon-btn" onClick={onClose} aria-label="Cerrar">
            <Icon name="x" />
          </button>
        </div>
        <div className="sheet-body">{children}</div>
        {footer && <div className="sheet-footer">{footer}</div>}
      </div>
    </div>
  );
}

/** Control − valor + con botones grandes */
export function Stepper({ value, onChange, step = 1, min = 0, max = 9999, format = (v) => v, label }) {
  const round = (v) => Math.round(v * 100) / 100;
  return (
    <div className="stepper">
      <button type="button" onClick={() => onChange(round(Math.max(min, value - step)))} aria-label="−" disabled={value <= min}>
        <Icon name="minus" size={24} stroke={2.5} />
      </button>
      <div className="stepper-value">
        <b>{format(value)}</b>
        {label && <small>{label}</small>}
      </div>
      <button type="button" onClick={() => onChange(round(Math.min(max, value + step)))} aria-label="+" disabled={value >= max}>
        <Icon name="plus" size={24} stroke={2.5} />
      </button>
    </div>
  );
}

/** Barra superior de cada pantalla */
export function TopBar({ title, subtitle, right, transparent = false, back = true, children }) {
  const navigate = useNavigate();
  const location = useLocation();
  const { tr } = useApp();
  const goBack = () => (location.key === 'default' ? navigate('/home') : navigate(-1));
  return (
    <header className={`topbar ${transparent ? 'transparent' : ''}`}>
      {back ? (
        <button className="icon-btn back-btn" onClick={goBack} aria-label={tr('Volver', 'Back')}>
          <Icon name="back" size={24} stroke={2.4} />
        </button>
      ) : (
        <span className="topbar-spacer" />
      )}
      <div className="topbar-title">
        {children || (
          <>
            {title && <h1>{title}</h1>}
            {subtitle && <small>{subtitle}</small>}
          </>
        )}
      </div>
      <div className="topbar-right">{right}</div>
    </header>
  );
}

export function Segmented({ options, value, onChange, small = false }) {
  return (
    <div className={`segmented ${small ? 'small' : ''}`}>
      {options.map((o) => (
        <button key={o.value} type="button" className={value === o.value ? 'active' : ''} onClick={() => onChange(o.value)}>
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function EmptyState({ icon = '☕', title, text, action }) {
  return (
    <div className="empty">
      <div className="empty-icon">{icon}</div>
      <h3>{title}</h3>
      {text && <p>{text}</p>}
      {action}
    </div>
  );
}
