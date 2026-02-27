import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../../core/constants.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, CupertinoIcons.square_grid_2x2, "হোম"),
                    const SizedBox(width: 60),
                    _navItem(2, CupertinoIcons.bag_fill, "ওয়ালেট"),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                onTap(1);
              },
              child: _miningActionBtn(currentIndex == 1),
            ),
          )
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool active = currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: active ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.emeraldLight : Colors.white, size: 24),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _miningActionBtn(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive ? [Colors.white, Colors.white] : [AppColors.emeraldLight, AppColors.emerald],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withOpacity(0.4),
              blurRadius: isActive ? 30 : 15,
              spreadRadius: isActive ? 5 : 2,
            )
          ],
        ),
        child: Icon(Icons.bolt, color: isActive ? AppColors.emerald : Colors.black, size: 30),
      ),
    );
  }
}
