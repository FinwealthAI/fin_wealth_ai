import 'package:flutter/material.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/widgets/strategy_card.dart';

class StrategyCardList extends StatelessWidget {
  final List<StrategyCardData> strategyCards;

  const StrategyCardList({
    Key? key,
    required this.strategyCards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (strategyCards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Cơ hội đầu tư',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: strategyCards.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final cardData = strategyCards[index];
              return StrategyCard(
                data: cardData,
                width: double.infinity,
                // height: null, // Auto height
              );
            },
          ),
      ],
    );
  }
}
