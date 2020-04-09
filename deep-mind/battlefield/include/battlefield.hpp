#pragma once

// #ifndef CONTRACT_NAME
//     static_assert(false, "The CONTRACT_NAME define should have been set by build system, aborting");
// #endif

#include <algorithm>
#include <string>

#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>
#include <eosio/time.hpp>
#include <eosio/transaction.hpp>

#include <eosio/key_value.hpp>

using eosio::action;
using eosio::action_wrapper;
using eosio::asset;
using eosio::cancel_deferred;
using eosio::check;
using eosio::const_mem_fun;
using eosio::contract;
using eosio::current_time_point;
using eosio::datastream;
using eosio::indexed_by;
using eosio::name;
using eosio::onerror;
using eosio::permission_level;
using eosio::print;
using eosio::time_point_sec;
using std::function;
using std::string;

class [[eosio::contract("battlefield")]] battlefield : public contract
{
public:
    battlefield(name receiver, name code, datastream<const char *> ds)
        : contract(receiver, code, ds) {}

    [[eosio::action]] void
    dbins(name account);

    [[eosio::action]] void dbinstwo(name account, uint64_t first, uint64_t second);

    [[eosio::action]] void dbupd(name account);

    [[eosio::action]] void dbrem(name account);

    [[eosio::action]] void dbremtwo(name account, uint64_t first, uint64_t second);

    [[eosio::action]] void dtrx(
        name account,
        bool fail_now,
        bool fail_later,
        bool fail_later_nested,
        uint32_t delay_sec,
        string nonce);

    [[eosio::action]] void dtrxcancel(name account);

    [[eosio::action]] void dtrxexec(name account, bool fail, bool failNested, string nonce);

    [[eosio::action]] void nestdtrxexec(bool fail);

    [[eosio::action]] void nestonerror(bool fail);

#if WITH_ONERROR_HANDLER == 1
    [[eosio::on_notify("eosio::onerror")]] void onerror(eosio::onerror data);
#endif

    /**
         * We are going to replicate the following creation order:
         *
         * ```
         * Legend:
         *  - a | Root Action
         *  - n | Notification (require_recipient)
         *  - c | Context Free Action Inline (send_context_free_inline)
         *  - i | Inline (send_inline)
         *
         *   Creation Tree
         *   a1
         *   ├── n1
         *   ├── i2
         *   |   ├── n4
         *   |   ├── n5
         *   |   ├── i3
         *   |   └── c3
         *   ├── n2
         *   |   ├── i1
         *   |   ├── c1
         *   |   └── n3
         *   └── c2
         *
         *   Execution Tree
         *   a1
         *   ├── n1
         *   ├── n2
         *   ├── n3
         *   ├── c2
         *   ├── c1
         *   ├── i2
         *   |   ├── n4
         *   |   ├── n5
         *   |   ├── c3
         *   |   └── i3
         *   └── i1
         * ```
         *
         * Consumer will pass the following information to create the hierarchy:
         *  - n1 The account notified in n1, must not have a contract
         *  - n2 The account notified in n2, must be an account with the
         *       battlefield account installed on it. Will accept the notification
         *       and will create i1, c1 and n3.
         *  - n3 The account notified in n3, must not have a contract, accessible
         *       through the notificiation of n2 (same context).
         *  - n4 The account notified in n4, must not have a contract
         *  - n5 The account notified in n5, must not have a contract
         *
         * The i1 and i3 will actually execute `inlineempty` with a tag of `"i1"`
         * and `"i3"` respectively.
         *
         * The c1, c2 and c3 will actually execute `eosio.null::nonce` with the
         * nonce being set to string `c1`, `c2` and `c3` respectively (which
         * renders as `026331`, `026332` and `026333` respectively in the
         * execution traces).
         *
         * The i2 will actually `require_recipient(n4)` and
         * `require_recipient(n5)` followed by a `inlineempty` with a tag of
         * `"i3"` and send `c3`
         */
    [[eosio::action]] void creaorder(name n1, name n2, name n3, name n4, name n5);

    [[eosio::on_notify("battlefield1::creaorder")]] void on_creaorder(name n1, name n2, name n3, name n4, name n5);

    [[eosio::action]] void inlineempty(string tag, bool fail);

    [[eosio::action]] void inlinedeep(
        string tag,
        name n4,
        name n5,
        string nestedInlineTag,
        bool nestedInlineFail,
        string nestedCfaInlineTag);

    // Inline action wrappers (so we can construct them in code)
    using nestdtrxexec_action = action_wrapper<"nestdtrxexec"_n, &battlefield::nestdtrxexec>;
    using nestonerror_action = action_wrapper<"nestonerror"_n, &battlefield::nestonerror>;
    using inlineempty_action = action_wrapper<"inlineempty"_n, &battlefield::inlineempty>;
    using inlinedeep_action = action_wrapper<"inlinedeep"_n, &battlefield::inlinedeep>;

    // KV Actions
    [[eosio::action]] void kvbios(name any);

    [[eosio::action]] void kv1insert(name any);

private:
    struct [[eosio::table]] member_row
    {
        uint64_t id;
        name account;
        asset amount;
        string memo;
        time_point_sec created_at;
        time_point_sec expires_at;

        auto primary_key() const { return id; }
        uint64_t by_account() const { return account.value; }
    };

    typedef eosio::multi_index<
        "member"_n, member_row,
        indexed_by<"byaccount"_n, const_mem_fun<member_row, uint64_t, &member_row::by_account>>>
        members;
};

// KV tables and stuff
struct [[eosio::table]] kv1_row
{
    uint64_t id;
    name account;
    asset amount;
    string memo;
    time_point_sec created_at;
    time_point_sec expires_at;

    auto primary_key() const { return id; }
    uint64_t by_account() const { return account.value; }
};

class kv_table1 : public eosio::kv_table<kv1_row>
{
public:
    kv_table1(name contract) : kv_table()
    {
        init(contract, "kvtable1"_n, eosio::kv_ram, primary_key, by_account);
    }

private:
    KV_NAMED_INDEX("pk"_n, primary_key);
    KV_NAMED_INDEX("byaccount"_n, by_account);
};
