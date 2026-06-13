package com.example.vault.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.theme.*

/** Defines the 5 bottom navigation destinations. */
sealed class NavDestination(
    val route: String,
    val icon: String,
    val label: String,
) {
    object Discover     : NavDestination("discover",     "◈",  "Discover")
    object Explore      : NavDestination("explore",      "⬡",  "Explore")
    object Capture      : NavDestination("capture",      "+",  "")
    object Library      : NavDestination("library",      "⊞",  "Library")
    object Profile      : NavDestination("profile",      "◎",  "Profile")
}

val navDestinations = listOf(
    NavDestination.Discover,
    NavDestination.Explore,
    NavDestination.Capture,
    NavDestination.Library,
    NavDestination.Profile,
)

/**
 * Floating bottom navigation bar — a blurred glass pill with 5 destinations.
 * The center item (Capture) is the FAB-style primary action.
 */
@Composable
fun BottomNavBar(
    currentRoute: String,
    onNavigate: (NavDestination) -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        contentAlignment = Alignment.BottomCenter,
    ) {
        GlassCard(
            shape    = XLargeCorner,
            elevation = GlassElevation.Level3,
            modifier  = Modifier.wrapContentWidth(),
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                navDestinations.forEach { dest ->
                    if (dest is NavDestination.Capture) {
                        // Capture — FAB-style center button
                        Box(
                            modifier = Modifier
                                .size(52.dp)
                                .clip(PillCorner)
                                .background(VaultAccent)
                                .clickable { onNavigate(dest) },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = "+",
                                color = VaultBackground,
                                fontSize = 26.sp,
                                fontWeight = FontWeight.Light,
                            )
                        }
                    } else {
                        NavItem(
                            dest       = dest,
                            isSelected = currentRoute == dest.route,
                            onClick    = { onNavigate(dest) },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NavItem(
    dest: NavDestination,
    isSelected: Boolean,
    onClick: () -> Unit,
) {
    val bgColor by animateColorAsState(
        targetValue = if (isSelected) VaultAccentMuted else androidx.compose.ui.graphics.Color.Transparent,
        animationSpec = spring(stiffness = Spring.StiffnessMedium),
        label = "nav_bg",
    )
    val iconColor by animateColorAsState(
        targetValue = if (isSelected) VaultAccent else VaultTextTertiary,
        animationSpec = spring(stiffness = Spring.StiffnessMedium),
        label = "nav_icon",
    )

    Column(
        modifier = Modifier
            .clip(MediumCorner)
            .background(bgColor)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Text(text = dest.icon, color = iconColor, fontSize = 18.sp)
        if (dest.label.isNotEmpty()) {
            Text(
                text = dest.label,
                color = iconColor,
                fontSize = 10.sp,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            )
        }
    }
}
