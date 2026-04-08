import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color bgCard       = Color(0xFF1B1B22);
  static const Color solanaGold   = Color(0xFFDC9C30);
}

// ─── Business Constants ───────────────────────────────────────────────────────
const double kEntryFee    = 18.0;
const double kUsdTarget   = 100.0;
const double kCoinsPerUsd = 1000.0;
const int    kNormalDays  = 360;
const int    kBoostDays   = 80;

// Fallback rate (used only before first API response)
const double kBaseUsdPerSec = kUsdTarget / (kNormalDays * 24 * 60 * 60);

