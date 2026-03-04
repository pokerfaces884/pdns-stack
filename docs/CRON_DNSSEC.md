
# DNSSEC 鍵ローテーション（cron 同梱）

このテンプレートは **CSK 1本運用**を前提にしています。
PowerDNS 自体は鍵管理（生成/有効化/無効化）を `pdnsutil` で提供しますが、
「完全自動で定期ローテーション」機能は標準ではないため、cronで半自動化します。

## 1) 事前準備
- `.env` に `DNSSEC_KEY_ALGO=ecdsa256` などを設定
- `docker compose up -d` で `pdns-auth` が起動していること

## 2) cron の例（年1回ローテ）

### 2-1) 1/1 に新鍵追加
```
0 3 1 1 * cd /path/to/pdns-complete && . ./.env && DOMAIN=$DOMAIN KEY_ALGO=$DNSSEC_KEY_ALGO ./scripts/cron/dnssec-rollover-addkey.sh >> ./backups/dnssec-rollover.log 2>&1
```

### 2-2) 2週間後に旧鍵無効化
```
0 3 15 1 * cd /path/to/pdns-complete && . ./.env && DOMAIN=$DOMAIN DRYRUN=0 ./scripts/cron/dnssec-rollover-deactivate-oldkey.sh >> ./backups/dnssec-rollover.log 2>&1
```

> 注意: DS の更新が必要な運用（KSK/CSK を変更する場合）は、
> `export-zone-ds` の結果をレジストラへ反映してください。

## 3) ドライラン
無効化スクリプトは `DRYRUN=1` でコマンドだけ表示します。

```bash
DOMAIN=example.com DRYRUN=1 ./scripts/cron/dnssec-rollover-deactivate-oldkey.sh
```
