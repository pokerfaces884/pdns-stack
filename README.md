
# PowerDNS Stack (dnsdist + Authoritative + Recursor + Admin) — テンプレート

PowerDNS Authoritative / Recursor / dnsdist / PowerDNS-Admin を Docker Compose で構築するテンプレートです。

- **dnsdistレート制限**（静的: `MaxQPSIPRule` + `TCAction`/`DropAction`/`MaxQPSRule`、動的: `dynBlockRulesGroup`）
- **上流フォワーダ**：IPv4 ×2、IPv6 ×2（`.=...` で全外部を転送）
- **DDNS（動的更新）無効**
- **DNSSEC対応**（CSKデフォルト。鍵ローテーションは `pdnsutil` / API を用いた半自動運用）

> 参考：
> - dnsdist レート制限: https://www.dnsdist.org/advanced/qpslimits.html / https://www.dnsdist.org/rules-actions.html / https://www.dnsdist.org/guides/dynblocks.html
> - Recursor フォワード構文: https://doc.powerdns.com/recursor/settings.html
> - DNSSEC（pdnsutil / CSK）: https://doc.powerdns.com/authoritative/dnssec/ / https://doc.powerdns.com/authoritative/dnssec/pdnsutil.html

---

## 動作要件
- Docker / Docker Compose v2
- `envsubst`（`gettext` パッケージ）

## 取得
```bash
git clone https://github.com/<YOUR-ORG>/pdns-stack.git
cd pdns-stack
```

## 初期設定
1. `.env` を作成
   ```bash
   cp .env.example .env
   ```
   - `DOMAIN` / `REVERSE_ZONE`
   - `DNSDIST_ACL`（IPv4 のみ）
   - `RECURSOR_ALLOW_FROM`（IPv4 のみ）
   - `RECURSOR_FORWARDERS_V4` / `RECURSOR_FORWARDERS_V6`（各2系統）

2. 設定生成
   ```bash
   ./scripts/00-render-configs.sh
   ```

3. 初回のみ（Authoritative SQLite 初期化）
   ```bash
   ./scripts/10-init-auth-sqlite.sh
   ```

4. 起動
   ```bash
   docker compose up -d
   ```

5. ゾーン作成 + DNSSEC
   ```bash
   ./scripts/20-create-zones-and-dnssec.sh
   ```

## 動作確認
```bash
# 権威ドメイン（IPv4クライアントから）
dig @<dnsdist_ipv4> www.${DOMAIN} A +short
dig @<dnsdist_ipv4> www.${DOMAIN} AAAA +short

# 外部ドメイン（forward 動作）
dig @<dnsdist_ipv4> www.google.com A +short
dig @<dnsdist_ipv4> www.google.com AAAA +short
```

## セキュリティ（IPv6クライアント不許可）
- dnsdist は IPv4 のみで待受
- Recursor も IPv6では待受しない
- OS側でも IPv6:53/tcp+udp を DROP することを推奨

## DNSSEC 鍵ローテーション（半自動の例）
```bash
# 新鍵追加＆有効化（CSK）
docker exec -it pdns-auth pdnsutil add-zone-key ${DOMAIN} active ecdsa256
# 猶予後に古い鍵無効化
docker exec -it pdns-auth pdnsutil list-zone-keys ${DOMAIN}
docker exec -it pdns-auth pdnsutil deactivate-zone-key ${DOMAIN} <OLD_KEY_ID>
# 必要に応じて DS を更新
docker exec -it pdns-auth pdnsutil export-zone-ds ${DOMAIN}
```

## ライセンス
MIT（必要に応じて置き換え）
