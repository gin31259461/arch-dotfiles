# Shared destination and retention policy for all configured backups.
BACKUP_TARGET="${HOME}/OneDrive"
BACKUP_RETENTION_DAYS=7

# Each key becomes the backup filename prefix and must be unique.
declare -A BACKUP_SOURCES=(
  [terraria]="${HOME}/.local/share/Terraria"
  # [documents]="${HOME}/Documents"
)
