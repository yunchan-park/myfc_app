import 'package:flutter/material.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/screens/splash_screen.dart';
import 'package:myfc_app/screens/home_screen.dart';
import 'package:myfc_app/screens/register_team_screen.dart';
import 'package:myfc_app/screens/team_profile_screen.dart';
import 'package:myfc_app/screens/edit_team_screen.dart';
import 'package:myfc_app/screens/player_management_screen.dart';
import 'package:myfc_app/screens/match_summary_screen.dart';
import 'package:myfc_app/screens/add_match_step1_screen.dart';
import 'package:myfc_app/screens/add_match_step2_screen.dart';
import 'package:myfc_app/screens/add_match_step3_screen.dart';
import 'package:myfc_app/screens/add_match_step4_screen.dart';
import 'package:myfc_app/screens/match_detail_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String registerTeam = '/register-team';
  static const String teamProfile = '/team-profile';
  static const String editTeam = '/edit-team';
  static const String registerPlayer = '/register-player';
  static const String playerList = '/player-list';
  static const String playerManagement = '/player-management';
  static const String matchSummary = '/match-summary';
  static const String addMatchStep1 = '/add-match-step1';
  static const String addMatchStep2 = '/add-match-step2';
  static const String addMatchStep3 = '/add-match-step3';
  static const String addMatchStep4 = '/add-match-step4';
  static const String matchDetail = '/match-detail';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case registerTeam:
        return MaterialPageRoute(builder: (_) => const RegisterTeamScreen());
      case teamProfile:
        return MaterialPageRoute(builder: (_) => const TeamProfileScreen());
      case editTeam:
        final team = settings.arguments as Team;
        return MaterialPageRoute(builder: (_) => EditTeamScreen(team: team));
      case registerPlayer:
        return MaterialPageRoute(builder: (_) => const PlayerManagementScreen());
      case playerList:
        return MaterialPageRoute(builder: (_) => const PlayerManagementScreen());
      case playerManagement:
        return MaterialPageRoute(builder: (_) => const PlayerManagementScreen());
      case matchSummary:
        return MaterialPageRoute(builder: (_) => const MatchSummaryScreen());
      case addMatchStep1:
        return MaterialPageRoute(builder: (_) => const AddMatchStep1Screen());
      case addMatchStep2:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => AddMatchStep2Screen(
          date: arguments['date'],
          opponent: arguments['opponent'],
          quarters: arguments['quarters'],
        ));
      case addMatchStep3:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => AddMatchStep3Screen(
          date: arguments['date'],
          opponent: arguments['opponent'],
          quarters: arguments['quarters'],
          playerIds: arguments['playerIds'],
        ));
      case addMatchStep4:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => AddMatchStep4Screen(
          matchData: arguments,
        ));
      case matchDetail:
        final matchId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => MatchDetailScreen(matchId: matchId));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 