
-- ===== Listen (IPv4 only) =====
setLocal("${DNSDIST_LISTEN_V4}")

-- ===== ACL =====
setACL({ "${DNSDIST_ACL}" })

-- ===== Downstreams =====
newServer({address="pdns-auth:53",     pool="auth"})
newServer({address="pdns-recursor:53", pool="rec"})

-- ===== Routing =====
local authSuffixes = newSuffixMatchNode()
authSuffixes:add(newDNSName("${DOMAIN}."))
authSuffixes:add(newDNSName("${REVERSE_ZONE}."))
addAction(SuffixMatchNodeRule(authSuffixes), PoolAction("auth"))
addAction(AllRule(), PoolAction("rec"))

-- ===== Web =====
webserver("${DNSDIST_WEB_LISTEN}", "${DNSDIST_WEB_PASSWORD}", 2, "${DNSDIST_WEB_ACL}")

-- =========================================================
-- Rate Limiting (static)
-- =========================================================
-- UDPのみTC=1にするため TCPRule(false) を併用
addAction(AndRule({ MaxQPSIPRule(${DNSDIST_RL_TC_QPS}), TCPRule(false) }), TCAction())
addAction(MaxQPSIPRule(${DNSDIST_RL_DROP_QPS}), DropAction())
addAction(NotRule(MaxQPSRule(${DNSDIST_RL_GLOBAL_QPS})), DropAction())

-- =========================================================
-- Rate Limiting (dynamic)
-- =========================================================
setRingBuffersSize(${DNSDIST_RINGBUF})
local dbr = dynBlockRulesGroup()
dbr:setQueryRate(${DNSDIST_DYN_QPS}, ${DNSDIST_DYN_WINDOW}, "Exceeded query rate", ${DNSDIST_DYN_BLOCK_SEC})
function maintenance() dbr:apply() end
