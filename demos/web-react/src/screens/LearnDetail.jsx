import { useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { EmptyState, TopBar } from '../components/ui';
import { LEARN } from '../data/learn';

export default function LearnDetail() {
  const { id } = useParams();
  const { tr, pick } = useApp();
  const item = LEARN.find((l) => l.id === id);
  if (!item) return <div className="screen"><TopBar /><EmptyState title="—" /></div>;
  return (
    <div className="screen">
      <TopBar title={tr('Aprende', 'Learn')} />
      <div className="screen-body">
        <div className="learn-hero" style={{ background: item.color }}>
          <span>{item.icon}</span>
        </div>
        <h1 className="learn-title">{pick(item.title)}</h1>
        <p className="muted"><Icon name="clock" size={13} /> {item.minutes} min · {pick(item.summary)}</p>
        <ol className="steps">
          {item.steps.map((s, i) => (
            <li key={i}>
              <span className="step-n">{i + 1}</span>
              <p>{pick(s)}</p>
            </li>
          ))}
        </ol>
        <div className="key-tip">
          <Icon name="sparkles" size={20} />
          <span><b>{tr('Clave', 'Key point')}</b> {pick(item.tip)}</span>
        </div>
      </div>
    </div>
  );
}
