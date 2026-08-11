const STATUS_MAP = {
  active:       { label: 'Active',       cls: 'badge--green' },
  suspended:    { label: 'Suspended',    cls: 'badge--yellow' },
  banned:       { label: 'Banned',       cls: 'badge--red' },
  restricted:   { label: 'Restricted',  cls: 'badge--orange' },
  deleted:      { label: 'Deleted',     cls: 'badge--grey' },
  open:         { label: 'Open',         cls: 'badge--red' },
  reviewing:    { label: 'Reviewing',   cls: 'badge--yellow' },
  resolved:     { label: 'Resolved',    cls: 'badge--green' },
  dismissed:    { label: 'Dismissed',   cls: 'badge--grey' },
  pending:      { label: 'Pending',     cls: 'badge--yellow' },
  under_review: { label: 'Under Review', cls: 'badge--yellow' },
  approved:     { label: 'Approved',    cls: 'badge--green' },
  rejected:     { label: 'Rejected',    cls: 'badge--red' },
  paid:         { label: 'Paid',        cls: 'badge--green' },
  failed:       { label: 'Failed',      cls: 'badge--red' },
  processing:   { label: 'Processing',  cls: 'badge--blue' },
  draft:        { label: 'Draft',       cls: 'badge--grey' },
  submitted:    { label: 'Submitted',   cls: 'badge--blue' },
  admin:        { label: 'Admin',       cls: 'badge--purple' },
  moderator:    { label: 'Moderator',   cls: 'badge--blue' },
  user:         { label: 'User',        cls: 'badge--grey' },
  true:         { label: 'Yes',         cls: 'badge--green' },
  false:        { label: 'No',          cls: 'badge--grey' },
};

export default function Badge({ value, label }) {
  const key = String(value).toLowerCase();
  const config = STATUS_MAP[key] || { label: label || value, cls: 'badge--grey' };
  return (
    <span className={`badge ${config.cls}`}>
      {label || config.label}
    </span>
  );
}
