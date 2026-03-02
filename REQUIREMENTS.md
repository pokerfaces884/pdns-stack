
# 要件まとめ

- **OS / ホスト**: AlmaLinux 10 上で Docker / Docker Compose で稼働
- **コンテナ**: dnsdist / PowerDNS Authoritative / PowerDNS Recursor / PowerDNS-Admin / SQLite3
- **権威DNS**:
  - バックエンド: SQLite（gsqlite3）
  - **DNSSEC 対応**（CSK デフォルト）。鍵ローテーションは `pdnsutil` / API を用いて半自動化
  - **DDNS（RFC2136 / DynDNS2）廃止**
- **リゾルバ（Recursor）**:
  - **外部のみ forward**: `example.com` と `1.168.192.in-addr.arpa` は権威へ、それ以外（`.`）は上流へ
  - 上流 **IPv4×2 / IPv6×2** を登録（例: `9.9.9.9;1.1.1.1;[2620:fe::fe];[2606:4700:4700::1111]`）
  - **オープンリゾルバ禁止**: `allow_from` は社内IPv4のみ
- **dnsdist（入口）**:
  - IPv4 のみで 53/tcp+udp を待受（IPv6 クライアントは不許可）
  - **レート制限**（静的: `MaxQPSIPRule` など、動的: `dynBlockRulesGroup`）
  - ACL は社内IPv4 + NAPT後グローバルIPv4のみ許可
- **IPv6 方針**:
  - **AAAA 参照は許可**（IPv4 クライアントからの AAAA 問い合わせ）
  - **IPv6 クライアントからの DNS アクセスは不許可**（dnsdist/Recursor で IPv6 リッスン無し + OS FW で DROP）
- **バックアップ**:
  - SQLite（権威 / Admin）は `.backup` 等で取得。復元時は停止してから置換
