package com.insightr.ui.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.screens.feed.FeedScreen
import com.insightr.ui.screens.actions.ActionsScreen
import com.insightr.ui.screens.search.SearchScreen
import com.insightr.ui.screens.vault.VaultScreen
import com.insightr.ui.screens.entry.EntryDetailScreen
import com.insightr.ui.screens.collections.CollectionsScreen
import com.insightr.ui.screens.collections.CollectionDetailScreen
import com.insightr.ui.screens.export.ExportScreen
import com.insightr.ui.screens.settings.SettingsScreen
import com.insightr.ui.screens.onboarding.OnboardingScreen
import com.insightr.ui.screens.processing.ProcessingScreen
import com.insightr.ui.screens.entry.DeepResearchScreen

data class BottomNavItem(
    val route: String,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
)

val bottomNavItems = listOf(
    BottomNavItem(Destinations.FEED, "Feed", Icons.Filled.Home, Icons.Outlined.Home),
    BottomNavItem(Destinations.ACTIONS, "Actions", Icons.Filled.CheckCircle, Icons.Outlined.CheckCircle),
    BottomNavItem(Destinations.SEARCH, "Search", Icons.Filled.Search, Icons.Outlined.Search),
    BottomNavItem(Destinations.VAULT, "Vault", Icons.Filled.Star, Icons.Outlined.Star)
)

@Composable
fun InsightrNavGraph(
    navController: NavHostController = rememberNavController(),
    startDestination: String = Destinations.FEED
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val showBottomBar = currentDestination?.route in bottomNavItems.map { it.route }

    Scaffold(
        containerColor = InsightrColors.Background,
        bottomBar = {
            if (showBottomBar) {
                NavigationBar(
                    containerColor = InsightrColors.BackgroundSecondary,
                    contentColor = InsightrColors.TextSecondary
                ) {
                    bottomNavItems.forEach { item ->
                        val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true
                        NavigationBarItem(
                            icon = {
                                Icon(
                                    imageVector = if (selected) item.selectedIcon else item.unselectedIcon,
                                    contentDescription = item.label
                                )
                            },
                            label = { Text(item.label) },
                            selected = selected,
                            onClick = {
                                navController.navigate(item.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = InsightrColors.Accent,
                                selectedTextColor = InsightrColors.Accent,
                                unselectedIconColor = InsightrColors.TextSecondary,
                                unselectedTextColor = InsightrColors.TextSecondary,
                                indicatorColor = InsightrColors.BackgroundSecondary
                            )
                        )
                    }
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier.padding(padding),
            enterTransition = { fadeIn(animationSpec = tween(300)) + slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Start, tween(300)) },
            exitTransition = { fadeOut(animationSpec = tween(300)) },
            popEnterTransition = { fadeIn(animationSpec = tween(300)) + slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.End, tween(300)) },
            popExitTransition = { fadeOut(animationSpec = tween(300)) }
        ) {
            composable(Destinations.FEED) {
                FeedScreen(
                    onEntryClick = { entryId -> navController.navigate(Destinations.entryDetail(entryId)) },
                    onAddClick = { navController.navigate("add_url") }
                )
            }

            composable(Destinations.ACTIONS) {
                ActionsScreen(
                    onEntryClick = { entryId -> navController.navigate(Destinations.entryDetail(entryId)) }
                )
            }

            composable(Destinations.SEARCH) {
                SearchScreen(
                    onEntryClick = { entryId -> navController.navigate(Destinations.entryDetail(entryId)) },
                    onConceptClick = { conceptId -> navController.navigate(Destinations.conceptDetail(conceptId)) }
                )
            }

            composable(Destinations.VAULT) {
                VaultScreen(
                    onConceptClick = { conceptId -> navController.navigate(Destinations.conceptDetail(conceptId)) },
                    onCollectionsClick = { navController.navigate(Destinations.COLLECTIONS) }
                )
            }

            composable(
                route = Destinations.ENTRY_DETAIL,
                arguments = listOf(navArgument("entryId") { type = NavType.IntType })
            ) {
                EntryDetailScreen(
                    onBackClick = { navController.popBackStack() },
                    onDeepResearch = { entryId -> navController.navigate(Destinations.deepResearch(entryId)) },
                    onConceptClick = { conceptId -> navController.navigate(Destinations.conceptDetail(conceptId)) },
                    onExport = { entryId -> navController.navigate(Destinations.export(entryId)) }
                )
            }

            composable(
                route = Destinations.DEEP_RESEARCH,
                arguments = listOf(navArgument("entryId") { type = NavType.IntType })
            ) {
                DeepResearchScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            composable(
                route = Destinations.CONCEPT_DETAIL,
                arguments = listOf(navArgument("conceptId") { type = NavType.IntType })
            ) {
                com.insightr.ui.screens.vault.ConceptDetailScreen(
                    onBackClick = { navController.popBackStack() },
                    onEntryClick = { entryId -> navController.navigate(Destinations.entryDetail(entryId)) }
                )
            }

            composable(Destinations.COLLECTIONS) {
                CollectionsScreen(
                    onBackClick = { navController.popBackStack() },
                    onCollectionClick = { name -> navController.navigate(Destinations.collectionDetail(name)) }
                )
            }

            composable(
                route = Destinations.COLLECTION_DETAIL,
                arguments = listOf(navArgument("name") { type = NavType.StringType })
            ) {
                CollectionDetailScreen(
                    onBackClick = { navController.popBackStack() },
                    onEntryClick = { entryId -> navController.navigate(Destinations.entryDetail(entryId)) }
                )
            }

            composable(
                route = Destinations.EXPORT,
                arguments = listOf(navArgument("entryId") { type = NavType.IntType })
            ) {
                ExportScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            composable(Destinations.SETTINGS) {
                SettingsScreen(
                    onBackClick = { navController.popBackStack() }
                )
            }

            composable(Destinations.ONBOARDING) {
                OnboardingScreen(
                    onComplete = {
                        navController.navigate(Destinations.FEED) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }

            composable(
                route = Destinations.PROCESSING,
                arguments = listOf(navArgument("url") { type = NavType.StringType })
            ) {
                ProcessingScreen(
                    onBackClick = { navController.popBackStack() },
                    onComplete = { entryId ->
                        navController.navigate(Destinations.entryDetail(entryId)) {
                            popUpTo(Destinations.FEED)
                        }
                    }
                )
            }

            composable(
                route = "add_url"
            ) {
                com.insightr.ui.screens.processing.AddUrlBottomSheet(
                    onDismiss = { navController.popBackStack() },
                    onProcess = { url -> navController.navigate(Destinations.processing(url)) }
                )
            }
        }
    }
}
