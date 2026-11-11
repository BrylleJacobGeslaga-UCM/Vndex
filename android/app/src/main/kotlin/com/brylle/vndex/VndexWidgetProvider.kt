package com.brylle.vndex

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Currently playing" home screen widget.
 * Reads the values saved by lib/services/home_widget_sync_io.dart.
 */
class VndexWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val titleIds = intArrayOf(R.id.widget_title_1, R.id.widget_title_2, R.id.widget_title_3)
        val subIds = intArrayOf(R.id.widget_sub_1, R.id.widget_sub_2, R.id.widget_sub_3)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.vndex_widget).apply {
                // Tap anywhere: open Vndex.
                val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, openApp)

                setTextViewText(R.id.widget_count, widgetData.getString("playing_count", "0") ?: "0")

                // Up to 3 titles; hide empty rows.
                var anyTitle = false
                for (i in 0 until 3) {
                    val title = widgetData.getString("title_${i + 1}", "") ?: ""
                    val sub = widgetData.getString("sub_${i + 1}", "") ?: ""
                    val visibility = if (title.isEmpty()) View.GONE else View.VISIBLE
                    if (title.isNotEmpty()) anyTitle = true
                    setViewVisibility(titleIds[i], visibility)
                    setViewVisibility(subIds[i], visibility)
                    setTextViewText(titleIds[i], title)
                    setTextViewText(subIds[i], sub)
                }
                setViewVisibility(R.id.widget_empty, if (anyTitle) View.GONE else View.VISIBLE)

                // Cover of the newest VN, or the app icon.
                val coverPath = widgetData.getString("cover_path", "") ?: ""
                val cover = if (coverPath.isNotEmpty()) BitmapFactory.decodeFile(coverPath) else null
                if (cover != null) {
                    setImageViewBitmap(R.id.widget_cover, cover)
                } else {
                    setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
