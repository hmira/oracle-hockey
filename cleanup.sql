
--cleanup
drop package zapas_db;

drop view V_zapasy;
drop view V_timy_body;
drop view V_statistiky_hracov;

drop sequence S_hokejista_id;
drop sequence S_tim_id;
drop sequence S_zapas_id;
drop sequence S_strela_na_branu_id;
drop sequence S_kontrakt_id;

drop trigger T_hokejista_id;
drop trigger T_tim_id;
drop trigger T_zapas_id;
drop trigger T_strela_na_branu_id;
drop trigger T_kontrakt_id;

drop trigger T_bef_ins_row_kontrakt;
drop trigger T_bef_ins_row_strela;
drop trigger T_bef_ins_row_gol;
drop trigger T_bef_ins_row_vylucenie;
drop trigger T_bef_ins_row_zapas;

drop table valid_pozicia cascade constraints;
drop table hokejista cascade constraints; --1
drop table tim cascade constraints; --2
drop table zapas cascade constraints; --3
drop table valid_typ_zapasu cascade constraints;
drop table valid_ukoncenie_zapasu cascade constraints;
drop table gol cascade constraints; --4
drop table strela_na_branu cascade constraints; --5
drop table valid_uspesnost_strely cascade constraints;
drop table vylucenie cascade constraints; --6
drop table kontrakt cascade constraints; --7