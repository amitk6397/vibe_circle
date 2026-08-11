export default function Spinner({ size = 'md', text = '' }) {
  return (
    <div className="spinner-wrapper">
      <div className={`spinner spinner--${size}`} />
      {text && <span className="spinner-text">{text}</span>}
    </div>
  );
}
