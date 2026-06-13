package com.example.vault.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

val VaultShapes = Shapes(
  // Chips, badges, small pills
  extraSmall = RoundedCornerShape(8.dp),
  // Cards, inputs, dialog content
  small      = RoundedCornerShape(12.dp),
  // Elevated cards, bottom sheets
  medium     = RoundedCornerShape(20.dp),
  // Hero cards, modal sheets
  large      = RoundedCornerShape(28.dp),
  // Floating pills (bottom nav, FAB)
  extraLarge = RoundedCornerShape(40.dp),
)

// Additional shape tokens for direct use
val SmallCorner  = RoundedCornerShape(8.dp)
val MediumCorner = RoundedCornerShape(16.dp)
val LargeCorner  = RoundedCornerShape(24.dp)
val XLargeCorner = RoundedCornerShape(32.dp)
val PillCorner   = RoundedCornerShape(50.dp)
