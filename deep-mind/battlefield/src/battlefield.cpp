#include "battlefield.hpp"
#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>
#include <eosiolib/transaction.hpp>
#include <eosiolib/action.hpp>

EOSIO_ABI(battlefield, (dbins)(dbinstwo)(dbupd)(dbrem)(dtrx)(dtrxcancel)(dtrxexec))

// @abi
void battlefield::dbins(account_name account) {
    require_auth(account);

    eosio::print("dbins ran and you're authenticated");

    members member_table(_self, _self);
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
void battlefield::dbinstwo(account_name account, uint64_t first, uint64_t second) {
    require_auth(account);

    members member_table(_self, _self);
    auto index = member_table.template get_index<N(byaccount)>();
    member_table.emplace(account, [&](auto& row) {
        row.id = first;
        row.account = first;
        row.memo = "inserted billed to calling account";
        row.created_at = time_point_sec(now());
    });

    member_table.emplace(_self, [&](auto& row) {
        row.id = second;
        row.account = second;
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

    index.modify(itr1, _self, [&](auto& row) {
        row.memo = "updated row 1";
    });

    index.modify(itr2, account, [&](auto& row) {
        row.account = N(dbupd);
        row.memo = "updated row 2";
    });
}

// @abi
void battlefield::dbrem(account_name account) {
    require_auth(account);

    members member_table(_self, _self);
    auto index = member_table.template get_index<N(byaccount)>();
    index.erase(index.find(N(dbops1)));
    index.erase(index.find(N(dbupd)));
}

// @abi
void battlefield::dtrx(account_name account, bool fail_now, bool fail_later, uint32_t delay_sec, std::string nonce) {
    require_auth(account);

    eosio::transaction deferred;
    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    deferred.actions.emplace_back(
      eosio::permission_level{_self, N(active) },
      _self,
       N(dtrxexec),
       std::make_tuple(account, fail_later, nonce)
    );
    deferred.delay_sec = delay_sec;
    deferred.send(sender_id, account, true);

    eosio_assert(!fail_now, "forced fail as requested by action parameters");
}

// @abi
void battlefield::dtrxcancel(account_name account) {
    require_auth(account);

    uint128_t sender_id = (uint128_t(0x1122334455667788) << 64) | uint128_t(0x1122334455667788);
    cancel_deferred(sender_id);
}

// @abi
void battlefield::dtrxexec(account_name account, bool fail, std::string nonce) {
  require_auth(account);
  eosio_assert(!fail, "instructed to fail");
}
