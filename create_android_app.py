import os
import shutil
from pathlib import Path

def create_file(path_str, content):
    p = Path(path_str)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n")

def scaffold():
    base = Path("VaultAndroidApp")
    if base.exists():
        shutil.rmtree(base)

    create_file("VaultAndroidApp/settings.gradle.kts", """
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "Vault"
include(":app")
""")

    create_file("VaultAndroidApp/build.gradle.kts", """
buildscript {
    ext {
        compose_version = "1.5.1"
    }
}
plugins {
    id("com.android.application") version "8.1.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}
""")

    create_file("VaultAndroidApp/gradle.properties", """
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
""")

    create_file("VaultAndroidApp/app/build.gradle.kts", """
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.vault"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.vault"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:1.6.2")
    implementation("androidx.activity:activity-compose:1.8.0")
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.navigation:navigation-compose:2.7.4")
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
    
    // Glassmorphism and UI enhancements
    implementation("androidx.compose.material:material-icons-extended:1.5.3")
}
""")

    create_file("VaultAndroidApp/app/src/main/AndroidManifest.xml", """
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:allowBackup="true"
        android:dataExtractionRules="true"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.Vault"
        android:usesCleartextTraffic="true"
        tools:targetApi="31">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Vault">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
""")

    create_file("VaultAndroidApp/app/src/main/res/xml/backup_rules.xml", """
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <include domain="sharedpref" path="."/>
</full-backup-content>
""")

    create_file("VaultAndroidApp/app/src/main/res/values/strings.xml", """
<resources>
    <string name="app_name">Vault</string>
</resources>
""")

    create_file("VaultAndroidApp/app/src/main/res/values/themes.xml", """
<resources>
    <style name="Theme.Vault" parent="android:Theme.Material.Light.NoActionBar" />
</resources>
""")

    # API Models & Service
    create_file("VaultAndroidApp/app/src/main/java/com/example/vault/data/VaultApi.kt", """
package com.example.vault.data

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import retrofit2.http.FormUrlUrlEncoded
import retrofit2.http.Field

data class CardSummary(
    val id: Int,
    val title: String,
    val headline: String,
    val field: String,
    val content_type: String,
    val tags: List<String>
)

data class FullEntry(
    val id: Int,
    val title: String,
    val source_url: String,
    val field: String,
    val tags: List<String>,
    val headline: String,
    val summary: String,
    val key_points: String,
    val next_step: String,
    val type_specific_fields: List<TypeField>,
    val action_items: List<ActionItem>,
    val extras: Extras
)

data class TypeField(val label: String, val value: String)
data class ActionItem(val text: String, val done: Boolean)
data class Extras(
    val referenced_artifacts: List<Artifact>,
    val claims: List<Claim>,
    val explore_further: List<String>,
    val concepts: List<Concept>
)

data class Artifact(val name: String, val type: String, val url: String?)
data class Claim(val claim: String, val verifiability: String, val note: String?)
data class Concept(val id: Int, val name: String, val concept_type: String, val summary: String)

data class ProcessResponse(val message: String, val task_id: String)

interface VaultApiService {
    @GET("/api/feed")
    suspend fun getFeed(@Query("limit") limit: Int = 50): List<CardSummary>

    @GET("/api/entries/{id}")
    suspend fun getEntry(@Path("id") id: Int): FullEntry

    @GET("/api/concepts")
    suspend fun getConcepts(): List<Concept>

    @GET("/api/search")
    suspend fun search(@Query("q") query: String): List<CardSummary>

    @POST("/api/process")
    suspend fun processUrl(@Query("url") url: String): ProcessResponse
}

object RetrofitClient {
    // Requires setting to the actual IP if running on device, 10.0.2.2 for emulator
    private const val BASE_URL = "http://10.0.2.2:8000"

    val apiService: VaultApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(VaultApiService::class.java)
    }
}
""")

    create_file("VaultAndroidApp/app/src/main/java/com/example/vault/viewmodel/VaultViewModel.kt", """
package com.example.vault.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.vault.data.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class VaultViewModel : ViewModel() {
    private val api = RetrofitClient.apiService

    private val _feed = MutableStateFlow<List<CardSummary>>(emptyList())
    val feed: StateFlow<List<CardSummary>> = _feed

    private val _concepts = MutableStateFlow<List<Concept>>(emptyList())
    val concepts: StateFlow<List<Concept>> = _concepts

    private val _searchResults = MutableStateFlow<List<CardSummary>>(emptyList())
    val searchResults: StateFlow<List<CardSummary>> = _searchResults

    private val _currentEntry = MutableStateFlow<FullEntry?>(null)
    val currentEntry: StateFlow<FullEntry?> = _currentEntry

    init {
        loadFeed()
        loadConcepts()
    }

    fun loadFeed() {
        viewModelScope.launch {
            try {
                _feed.value = api.getFeed()
            } catch (e: Exception) { e.printStackTrace() }
        }
    }

    fun loadConcepts() {
        viewModelScope.launch {
            try {
                _concepts.value = api.getConcepts()
            } catch (e: Exception) { e.printStackTrace() }
        }
    }

    fun search(query: String) {
        viewModelScope.launch {
            try {
                _searchResults.value = api.search(query)
            } catch (e: Exception) { e.printStackTrace() }
        }
    }

    fun loadEntry(id: Int) {
        viewModelScope.launch {
            try {
                _currentEntry.value = api.getEntry(id)
            } catch (e: Exception) { e.printStackTrace() }
        }
    }

    fun processUrl(url: String) {
        viewModelScope.launch {
            try {
                api.processUrl(url)
                // In a real app, we would poll for status. For now, just refresh after a delay.
            } catch (e: Exception) { e.printStackTrace() }
        }
    }
}
""")

    create_file("VaultAndroidApp/app/src/main/java/com/example/vault/ui/theme/Color.kt", """
package com.example.vault.ui.theme

import androidx.compose.ui.graphics.Color

val OliveBackground = Color(0xFF1E1E1A) // Deep warm grey/olive
val CardGlass = Color(0xFFFFFFFF).copy(alpha = 0.08f)
val CardBorder = Color(0xFFFFFFFF).copy(alpha = 0.15f)
val AccentPill = Color(0xFFF0EFEA)
val TextPrimary = Color(0xFFF4F3F0)
val TextSecondary = Color(0xFFA5A39B)
val InteractiveOlive = Color(0xFF3C3B33)
""")

    create_file("VaultAndroidApp/app/src/main/java/com/example/vault/ui/theme/Theme.kt", """
package com.example.vault.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val VaultColorScheme = darkColorScheme(
    background = OliveBackground,
    surface = CardGlass,
    primary = AccentPill,
    onPrimary = OliveBackground,
    onBackground = TextPrimary,
    onSurface = TextPrimary
)

@Composable
fun VaultTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = VaultColorScheme,
        content = content
    )
}
""")

    create_file("VaultAndroidApp/app/src/main/java/com/example/vault/ui/VaultApp.kt", """
package com.example.vault.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import androidx.navigation.compose.*
import com.example.vault.data.CardSummary
import com.example.vault.data.FullEntry
import com.example.vault.ui.theme.*
import com.example.vault.viewmodel.VaultViewModel
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun VaultApp() {
    val navController = rememberNavController()
    val viewModel: VaultViewModel = viewModel()
    
    Scaffold(
        bottomBar = { BottomNavBar(navController) },
        containerColor = OliveBackground
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color(0xFF262520), OliveBackground)
                    )
                )
        ) {
            NavHost(navController = navController, startDestination = "feed") {
                composable("feed") { FeedScreen(viewModel, navController) }
                composable("concepts") { ConceptsScreen(viewModel) }
                composable("search") { SearchScreen(viewModel, navController) }
                composable("add") { AddScreen(viewModel) }
                composable("detail/{id}") { backStackEntry ->
                    val id = backStackEntry.arguments?.getString("id")?.toIntOrNull()
                    if (id != null) {
                        DetailScreen(id, viewModel, navController)
                    }
                }
            }
        }
    }
}

@Composable
fun BottomNavBar(navController: NavController) {
    NavigationBar(
        containerColor = OliveBackground.copy(alpha = 0.95f),
        contentColor = TextPrimary,
        tonalElevation = 0.dp
    ) {
        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentRoute = navBackStackEntry?.destination?.route

        NavigationBarItem(
            icon = { Icon(Icons.Default.Home, contentDescription = "Feed") },
            label = { Text("Feed") },
            selected = currentRoute == "feed",
            onClick = { navController.navigate("feed") },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = OliveBackground,
                selectedTextColor = AccentPill,
                indicatorColor = AccentPill,
                unselectedIconColor = TextSecondary,
                unselectedTextColor = TextSecondary
            )
        )
        NavigationBarItem(
            icon = { Icon(Icons.Default.Lightbulb, contentDescription = "Concepts") },
            label = { Text("Concepts") },
            selected = currentRoute == "concepts",
            onClick = { navController.navigate("concepts") },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = OliveBackground,
                selectedTextColor = AccentPill,
                indicatorColor = AccentPill,
                unselectedIconColor = TextSecondary,
                unselectedTextColor = TextSecondary
            )
        )
        NavigationBarItem(
            icon = { Icon(Icons.Default.Search, contentDescription = "Search") },
            label = { Text("Search") },
            selected = currentRoute == "search",
            onClick = { navController.navigate("search") },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = OliveBackground,
                selectedTextColor = AccentPill,
                indicatorColor = AccentPill,
                unselectedIconColor = TextSecondary,
                unselectedTextColor = TextSecondary
            )
        )
        NavigationBarItem(
            icon = { Icon(Icons.Default.Add, contentDescription = "Add") },
            label = { Text("Add") },
            selected = currentRoute == "add",
            onClick = { navController.navigate("add") },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = OliveBackground,
                selectedTextColor = AccentPill,
                indicatorColor = AccentPill,
                unselectedIconColor = TextSecondary,
                unselectedTextColor = TextSecondary
            )
        )
    }
}

@Composable
fun FeedScreen(viewModel: VaultViewModel, navController: NavController) {
    val feed by viewModel.feed.collectAsState()
    
    LaunchedEffect(Unit) {
        viewModel.loadFeed()
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = "Smart Vault, Simplified",
            color = TextPrimary,
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(24.dp, 32.dp, 24.dp, 16.dp),
            lineHeight = 36.sp
        )
        Text(
            text = "Your curated knowledge base.",
            color = TextSecondary,
            fontSize = 16.sp,
            modifier = Modifier.padding(horizontal = 24.dp).padding(bottom = 24.dp)
        )
        LazyColumn(contentPadding = PaddingValues(horizontal = 24.dp, vertical = 8.dp)) {
            items(feed) { card ->
                FeedCard(card) {
                    navController.navigate("detail/${card.id}")
                }
            }
        }
    }
}

@Composable
fun FeedCard(card: CardSummary, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 16.dp)
            .clip(RoundedCornerShape(24.dp))
            .background(CardGlass)
            .border(1.dp, CardBorder, RoundedCornerShape(24.dp))
            .clickable { onClick() }
            .padding(20.dp)
    ) {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .background(AccentPill, CircleShape)
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(card.field, color = OliveBackground, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(card.content_type.replace("_", " ").capitalize(), color = TextSecondary, fontSize = 12.sp)
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(card.title, color = TextPrimary, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            Text(card.headline, color = TextSecondary, fontSize = 14.sp)
        }
    }
}

@Composable
fun DetailScreen(id: Int, viewModel: VaultViewModel, navController: NavController) {
    val entry by viewModel.currentEntry.collectAsState()
    
    LaunchedEffect(id) {
        viewModel.loadEntry(id)
    }

    if (entry == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = AccentPill)
        }
    } else {
        val e = entry!!
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(24.dp)
        ) {
            item {
                IconButton(onClick = { navController.popBackStack() }, modifier = Modifier.background(InteractiveOlive, CircleShape)) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = TextPrimary)
                }
                Spacer(modifier = Modifier.height(24.dp))
                
                Text(e.title, color = TextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold, lineHeight = 38.sp)
                Spacer(modifier = Modifier.height(16.dp))
                
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(24.dp))
                        .background(CardGlass)
                        .border(1.dp, CardBorder, RoundedCornerShape(24.dp))
                        .padding(20.dp)
                ) {
                    Column {
                        Text(e.headline, color = AccentPill, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(e.summary, color = TextSecondary, fontSize = 15.sp, lineHeight = 22.sp)
                        
                        Spacer(modifier = Modifier.height(20.dp))
                        Divider(color = CardBorder)
                        Spacer(modifier = Modifier.height(20.dp))
                        
                        Text("Key Points", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(e.key_points, color = TextSecondary, fontSize = 15.sp, lineHeight = 24.sp)
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // Action Items
            if (e.action_items.isNotEmpty()) {
                item {
                    Text("Action Items", color = TextPrimary, fontSize = 20.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(vertical = 12.dp))
                    e.action_items.forEach { action ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 8.dp)
                                .clip(RoundedCornerShape(16.dp))
                                .background(CardGlass)
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                if (action.done) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                                contentDescription = null,
                                tint = if (action.done) AccentPill else TextSecondary
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(action.text, color = TextPrimary, fontSize = 15.sp)
                        }
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }

            // Concepts (Extras mapping)
            if (e.extras.concepts.isNotEmpty()) {
                item {
                    Text("Related Concepts", color = TextPrimary, fontSize = 20.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(vertical = 12.dp))
                    e.extras.concepts.forEach { concept ->
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 8.dp)
                                .clip(RoundedCornerShape(16.dp))
                                .background(InteractiveOlive)
                                .border(1.dp, CardBorder, RoundedCornerShape(16.dp))
                                .padding(16.dp)
                        ) {
                            Column {
                                Text(concept.name, color = TextPrimary, fontWeight = FontWeight.Bold)
                                Text(concept.summary, color = TextSecondary, fontSize = 13.sp)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ConceptsScreen(viewModel: VaultViewModel) {
    val concepts by viewModel.concepts.collectAsState()
    
    LazyColumn(contentPadding = PaddingValues(24.dp)) {
        item {
            Text("Knowledge Graph", color = TextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(24.dp))
        }
        items(concepts) { concept ->
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(CardGlass)
                    .border(1.dp, CardBorder, RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Row {
                        Box(modifier = Modifier.background(AccentPill, CircleShape).padding(horizontal = 8.dp, vertical = 4.dp)) {
                            Text(concept.concept_type.toUpperCase(), color = OliveBackground, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(concept.name, color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(concept.summary, color = TextSecondary, fontSize = 14.sp)
                }
            }
        }
    }
}

@Composable
fun SearchScreen(viewModel: VaultViewModel, navController: NavController) {
    var query by remember { mutableStateOf("") }
    val results by viewModel.searchResults.collectAsState()

    Column(modifier = Modifier.fillMaxSize().padding(24.dp)) {
        Text("Search", color = TextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(16.dp))
        
        OutlinedTextField(
            value = query,
            onValueChange = { 
                query = it
                viewModel.search(it)
            },
            placeholder = { Text("Find anything...", color = TextSecondary) },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = TextFieldDefaults.outlinedTextFieldColors(
                containerColor = CardGlass,
                textColor = TextPrimary,
                unfocusedBorderColor = CardBorder,
                focusedBorderColor = AccentPill
            )
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        LazyColumn {
            items(results) { card ->
                FeedCard(card) {
                    navController.navigate("detail/${card.id}")
                }
            }
        }
    }
}

@Composable
fun AddScreen(viewModel: VaultViewModel) {
    var url by remember { mutableStateOf("") }
    var submitted by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.Center) {
        Text("Ingest Content", color = TextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold)
        Text("Paste a reel, video, or post URL to extract knowledge.", color = TextSecondary, fontSize = 16.sp)
        Spacer(modifier = Modifier.height(32.dp))
        
        OutlinedTextField(
            value = url,
            onValueChange = { url = it },
            placeholder = { Text("https://...", color = TextSecondary) },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(24.dp),
            colors = TextFieldDefaults.outlinedTextFieldColors(
                containerColor = CardGlass,
                textColor = TextPrimary,
                unfocusedBorderColor = CardBorder,
                focusedBorderColor = AccentPill
            )
        )
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(
            onClick = { 
                viewModel.processUrl(url)
                submitted = true
                url = ""
            },
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(28.dp),
            colors = ButtonDefaults.buttonColors(containerColor = AccentPill, contentColor = OliveBackground)
        ) {
            Text("Process and Extract", fontSize = 16.sp, fontWeight = FontWeight.Bold)
        }
        
        if (submitted) {
            Spacer(modifier = Modifier.height(16.dp))
            Text("Processing in background. Check the Feed soon.", color = AccentPill, fontSize = 14.sp)
        }
    }
}
""")

    create_file("VaultAndroidApp/app/src/main/java/com/example/vault/MainActivity.kt", """
package com.example.vault

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.example.vault.ui.VaultApp
import com.example.vault.ui.theme.VaultTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            VaultTheme {
                VaultApp()
            }
        }
    }
}
""")

    print("Android project successfully created at VaultAndroidApp/")

if __name__ == "__main__":
    scaffold()
