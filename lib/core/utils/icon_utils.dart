import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IconUtils {
  IconUtils._();

  static const IconData fallback = PhosphorIconsFill.receipt;

  static final Map<int, IconData> _phosphorByCodePoint = {
    // Expense icons
    PhosphorIconsFill.shoppingCart.codePoint: PhosphorIconsFill.shoppingCart,
    PhosphorIconsFill.forkKnife.codePoint: PhosphorIconsFill.forkKnife,
    PhosphorIconsFill.car.codePoint: PhosphorIconsFill.car,
    PhosphorIconsFill.airplane.codePoint: PhosphorIconsFill.airplane,
    PhosphorIconsFill.bag.codePoint: PhosphorIconsFill.bag,
    PhosphorIconsFill.filmSlate.codePoint: PhosphorIconsFill.filmSlate,
    PhosphorIconsFill.creditCard.codePoint: PhosphorIconsFill.creditCard,
    PhosphorIconsFill.lightning.codePoint: PhosphorIconsFill.lightning,
    PhosphorIconsFill.heartbeat.codePoint: PhosphorIconsFill.heartbeat,
    PhosphorIconsFill.sparkle.codePoint: PhosphorIconsFill.sparkle,
    PhosphorIconsFill.graduationCap.codePoint: PhosphorIconsFill.graduationCap,
    PhosphorIconsFill.wrench.codePoint: PhosphorIconsFill.wrench,
    PhosphorIconsFill.shieldCheck.codePoint: PhosphorIconsFill.shieldCheck,
    PhosphorIconsFill.house.codePoint: PhosphorIconsFill.house,
    PhosphorIconsFill.dotsThreeOutline.codePoint: PhosphorIconsFill.dotsThreeOutline,
    // Income icons
    PhosphorIconsFill.wallet.codePoint: PhosphorIconsFill.wallet,
    PhosphorIconsFill.coins.codePoint: PhosphorIconsFill.coins,
    PhosphorIconsFill.laptop.codePoint: PhosphorIconsFill.laptop,
    PhosphorIconsFill.chartLineUp.codePoint: PhosphorIconsFill.chartLineUp,
    PhosphorIconsFill.bank.codePoint: PhosphorIconsFill.bank,
    PhosphorIconsFill.gift.codePoint: PhosphorIconsFill.gift,
    PhosphorIconsFill.plusCircle.codePoint: PhosphorIconsFill.plusCircle,
    // Custom category default
    PhosphorIconsFill.tag.codePoint: PhosphorIconsFill.tag,
  };

  static IconData fromCodePoint(int? codePoint) {
    if (codePoint == null) return fallback;
    return _phosphorByCodePoint[codePoint] ?? fallback;
  }
}
