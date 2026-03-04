
# PowerDNS Stack（dnsdist + Authoritative + Recursor + Admin）— 完成版テンプレート

PowerDNS Authoritative / Recursor / dnsdist / PowerDNS-Admin を Docker Compose で構築するテンプレートです。

- **dnsdist レート制限**（静的 + 動的）
- **上流フォワーダ**：IPv4 ×2、IPv6 ×2（外部のみ forward）
- **DDNS 廃止**
- **DNSSEC 対応**（Online Signing / CSKデフォ）
- **IPv6方針**：AAAA参照は許可、IPv6クライアントからのDNSアクセスは不許可（IPv4のみ待受）

## 1. 動作要件
- Docker / Docker Compose v2
- `envsubst`（AlmaLinux: `sudo dnf -y install gettext`）

## 2. セットアップ

```bash
cp .env.example .env
# .env を編集（ACL・上流フォワーダなど）
chmod +x scripts/*.sh scripts/cron/*.sh
./scripts/00-render-configs.sh
./scripts/10-init-auth-sqlite.sh   # 初回のみ
docker compose up -d
./scripts/20-create-zones-and-dnssec.sh
```

## 3. 動作確認

```bash
# 権威（内部）
dig @<dnsdist_ipv4> www.${DOMAIN} A +short
# AAAA参照（IPv4クライアントから）
dig @<dnsdist_ipv4> www.google.com AAAA +short
# 外部 forward
dig @<dnsdist_ipv4> www.google.com A +short
```

## 4. DNSSEC（追加手順）

### 4.1 初回（ゾーン署名）

```bash
docker exec -it pdns-auth pdnsutil zone secure ${DOMAIN}
docker exec -it pdns-auth pdnsutil rectify-zone ${DOMAIN}
```

外部公開する場合は DS を取得してレジストラへ登録します：

```bash
docker exec -it pdns-auth pdnsutil export-zone-ds ${DOMAIN}
```

### 4.2 鍵ローテーション（cron 同梱）

- スクリプト：`scripts/cron/` に同梱
- 手順：`docs/CRON_DNSSEC.md` を参照

---

## 5. 重要: IPv6クライアント不許可
- dnsdist/recursor は IPv4 のみで待受（IPv6で listen しない）
- OSレベルでも IPv6:53 を DROP 推奨

---

## 6. 収録ファイル
- `.gitignore`（推奨）
- `REQUIREMENTS.md`（要件まとめ）
