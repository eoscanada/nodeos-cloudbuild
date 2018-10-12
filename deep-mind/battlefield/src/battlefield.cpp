#include "battlefield.hpp"
#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include <eosiolib/transaction.hpp>
#include <eosiolib/action.hpp>

EOSIO_ABI(battlefield, (dbins)(dbupd)(dbrem)(dtrx)(dtrxcancel)(dtrxexec))

// @abi
void battlefield::dbins(account_name account) {
    require_auth(account);

    members member_table(_self, _self);
    auto index = member_table.template get_index<N(byaccount)>();
    member_table.emplace(account, [&](auto& row) {
        row.id = 1;
        row.account = N(dbops1);
        row.memo = "inserted billed to calling account";
        row.created_at = time_point_sec(now());
    });

    member_table.emplace(_self, [&](auto& row) {
        row.id = 2;
        row.account = N(dbops2);
        row.memo = "inserted billed to self";
        row.created_at = time_point_sec(now());
    });
}

// @abi
void battlefield::dbupd(account_name account) {
    require_auth(account);

    members member_table(_self, _self);
    auto index = member_table.template get_index<N(byaccount)>();
    auto itr1 = index.find(N(dbops1));
    auto itr2 = index.find(N(dbops2));

    index.modify(itr1, 0, [&](auto& row) {
        row.memo = "updated row 1";
      });
    index.modify(itr2, 0, [&](auto& row) {
        row.memo = "updated row 2";
      });
}

// @abi
void battlefield::dbrem(account_name account) {
    require_auth(account);

    members member_table(_self, _self);
    auto index = member_table.template get_index<N(byaccount)>();
    index.erase(index.find(N(dbops1)));
    index.erase(index.find(N(dbops2)));
}

// @abi
void battlefield::dtrx(account_name account, bool fail) {
    require_auth(account);

    eosio::transaction deferred;
    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    deferred.actions.emplace_back( eosio::permission_level{_self, N(active) }, _self, N(dtrxexec), account);
    deferred.delay_sec = 1;
    deferred.send(sender_id, account, true);

    if (fail) {
        eosio_assert(false, "forced fail as requested by action parameters");
    }
}

// @abi
void battlefield::dtrxcancel(account_name account) {
    require_auth(account);

    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    cancel_deferred(sender_id);
}

// @abi
void battlefield::dtrxexec(account_name account) {
  require_auth(account);
}
