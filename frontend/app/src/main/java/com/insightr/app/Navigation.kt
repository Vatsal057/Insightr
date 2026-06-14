package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

/* =========================================================================
 * BOTTOM NAV
 * Five destinations cover every Python-side feature:
 *  - Home: feed/search (db.py search, list)
 *  - Add: process pipeline (main.py `process`)
 *  - Todo: action items across entries (main.py `todo`/`check`)
 *  - Collections: (main.py `collection`)
 *  - Cards: knowledge cards (main.py `cards`)
 * ====================================================================== */

data class BottomNavItem(
    val route: String,
    val label: String,
    val icon: ImageVector,
    val outlinedIcon: ImageVector
)

val bottomNavItems = listOf(
    BottomNavItem(Routes.HOME, "Home", Icons.Filled.Home, Icons.Outlined.Home),
    BottomNavItem(Routes.TODO, "Todo", Icons.Filled.CheckCircle, Icons.Outlined.CheckCircle),
    BottomNavItem(Routes.ADD, "Add", Icons.Filled.AddCircle, Icons.Outlined.AddCircle),
    BottomNavItem(Routes.COLLECTIONS, "Vaults", Icons.Filled.Folder, Icons.Outlined.Folder),
    BottomNavItem(Routes.CARDS, "Cards", Icons.Filled.Style, Icons.Outlined.Style)
)

@Composable
fun InsightrApp() {
    val navController = rememberNavController()

    Scaffold(
        containerColor = InsightrColors.BackgroundDark,
        bottomBar = { InsightrBottomBar(navController) }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Routes.ONBOARDING,
            modifier = Modifier.padding(bottom = innerPadding.calculateBottomPadding())
        ) {
            composable(Routes.ONBOARDING) {
                OnboardingScreen(onGetStarted = {
                    navController.navigate(Routes.HOME) {
                        popUpTo(Routes.ONBOARDING) { inclusive = true }
                    }
                })
            }
            composable(Routes.HOME) {
                HomeScreen(
                    onEntryClick = { id -> navController.navigate(Routes.entryDetail(id)) },
                    onAddClick = { navController.navigate(Routes.ADD) },
                    onSettingsClick = { navController.navigate(Routes.SETTINGS) }
                )
            }
            composable(Routes.SETTINGS) {
                SettingsScreen(onBack = { navController.popBackStack() })
            }
            composable(Routes.ADD) {
                AddContentScreen(
                    onDone = { id ->
                        navController.navigate(Routes.entryDetail(id)) {
                            popUpTo(Routes.HOME)
                        }
                    }
                )
            }
            composable(Routes.TODO) {
                TodoScreen(onEntryClick = { id -> navController.navigate(Routes.entryDetail(id)) })
            }
            composable(Routes.COLLECTIONS) {
                CollectionsScreen(onCollectionClick = { name ->
                    navController.navigate(Routes.collectionDetail(name))
                })
            }
            composable(Routes.COLLECTION_DETAIL) { backStackEntry ->
                val name = backStackEntry.arguments?.getString("name") ?: ""
                CollectionDetailScreen(
                    name = name,
                    onEntryClick = { id -> navController.navigate(Routes.entryDetail(id)) },
                    onBack = { navController.popBackStack() }
                )
            }
            composable(Routes.CARDS) {
                CardsScreen(onCardClick = { id -> navController.navigate(Routes.cardDetail(id)) })
            }
            composable(Routes.CARD_DETAIL) { backStackEntry ->
                val cardId = backStackEntry.arguments?.getString("cardId")?.toIntOrNull() ?: -1
                CardDetailScreen(
                    cardId = cardId,
                    onEntryClick = { id -> navController.navigate(Routes.entryDetail(id)) },
                    onBack = { navController.popBackStack() }
                )
            }
            composable(Routes.ENTRY_DETAIL) { backStackEntry ->
                val entryId = backStackEntry.arguments?.getString("entryId")?.toIntOrNull() ?: -1
                EntryDetailScreen(
                    entryId = entryId,
                    onBack = { navController.popBackStack() },
                    onEntryClick = { id -> navController.navigate(Routes.entryDetail(id)) },
                    onCardClick = { id -> navController.navigate(Routes.cardDetail(id)) }
                )
            }
        }
    }
}

@Composable
fun InsightrBottomBar(navController: NavHostController) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination

    // Hide the bottom bar on onboarding and detail screens for an immersive feel
    val hiddenRoutes = setOf(
        Routes.ONBOARDING, Routes.ENTRY_DETAIL, Routes.COLLECTION_DETAIL, Routes.CARD_DETAIL, Routes.SETTINGS
    )
    if (currentRoute?.hierarchy?.any { it.route in hiddenRoutes } == true) return

    NavigationBar(
        containerColor = InsightrColors.BackgroundDarkAlt,
        contentColor = InsightrColors.TextOnDark
    ) {
        bottomNavItems.forEach { item ->
            val selected = currentRoute?.hierarchy?.any { it.route == item.route } == true
            NavigationBarItem(
                selected = selected,
                onClick = {
                    navController.navigate(item.route) {
                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                icon = {
                    Icon(
                        imageVector = if (selected) item.icon else item.outlinedIcon,
                        contentDescription = item.label
                    )
                },
                label = { Text(item.label) },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = InsightrColors.TextOnCream,
                    selectedTextColor = InsightrColors.Accent,
                    indicatorColor = InsightrColors.Accent,
                    unselectedIconColor = InsightrColors.TextOnDarkMuted,
                    unselectedTextColor = InsightrColors.TextOnDarkMuted
                )
            )
        }
    }
}
