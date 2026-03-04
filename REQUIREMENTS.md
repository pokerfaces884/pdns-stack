
# 要件まとめ

- **OS / ホスト**: AlmaLinux 10 上で Docker / Docker Compose で稼働
- **コンテナ**: dnsdist / PowerDNS Authoritative / PowerDNS Recursor / PowerDNS-Admin / SQLite3
- **ドメイン**: `example.com`
- **内部セグメント**: `192.168.1.0/24`

## 権威DNS（PowerDNS Authoritative）
- バックエンド: SQLite（gsqlite3）
- DNSSEC 対応（Online Signing, CSK デフォルト）
- DDNS（RFC2136 / DynDNS2）: **廃止**

## リゾルバ（PowerDNS Recursor）
- 外部のみ forward:
  - `example.com` と `1.168.192.in-addr.arpa` は権威へ
  - それ以外（`.`）は上流へ
- 上流フォワーダ: **IPv4×2 / IPv6×2**
- オープンリゾルバ禁止: `allow_from` は社内 IPv4 のみに限定

## dnsdist（入口）
- 53/tcp+udp を **IPv4 のみ**で待受（IPv6 クライアントは不許可）
- ACL: 社内 IPv4 + NAPT 後グローバル IPv4 のみ許可
- レート制限:
  - 静的（MaxQPSIPRule, TCAction, DropAction, MaxQPSRule）
  - 動的（dynBlockRulesGroup）

## IPv6 方針
- AAAA 参照は許可（IPv4クライアントから AAAA 問い合わせ）
- IPv6 クライアントからの DNS アクセスは不許可（dnsdist/recursor で IPv6 リッスンなし + OS で DROP 推奨）

## データ保全
- SQLite（権威 / Admin）は `.backup` 等で取得。復元時は停止してから置換
