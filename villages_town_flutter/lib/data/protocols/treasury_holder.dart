import 'dart:math';

mixin TreasuryHolder {
  double get money;
  set money(double value);

  void addMoney(double amount) => money += amount;
  void subtractMoney(double amount) => money = max(0, money - amount);
  bool isSufficientMoney(double amount) => money >= amount;
}
