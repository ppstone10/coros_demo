package com.example.demo.harmony.bridge

import com.example.demo.common.health.model.HealthState

/** 健康快照 JSON 序列化（healthSnapshotFromState）与字符串转义，保持 KNOI 契约稳定。 */
fun healthSnapshotFromState(state: HealthState): String {
    val uiState = state.uiState ?: return "{}"
    val sb = StringBuilder()
    sb.append("{\"scenario\":\"")
    sb.append(state.currentScenario.name)
    sb.append("\",\"dateLabelKey\":\"")
    sb.append(uiState.dateLabel.key.esc())
    sb.append("\",\"steps\":")
    sb.append(uiState.dailySummary?.steps ?: 0)
    sb.append(",\"calories\":")
    sb.append(uiState.dailySummary?.calories ?: 0)
    sb.append(",\"activeMinutes\":")
    sb.append(uiState.dailySummary?.activeMinutes ?: 0)
    sb.append(",\"cards\":[")
    uiState.cards.forEachIndexed { index, card ->
        if (index > 0) sb.append(",")
        sb.append("{\"type\":\"")
        sb.append(card.type.name)
        sb.append("\",\"titleKey\":\"")
        sb.append(card.title.key.esc())
        sb.append("\",\"summaryKey\":\"")
        sb.append(card.summary.key.esc())
        sb.append("\",\"summaryArgs\":[")
        card.summary.arguments.forEachIndexed { argumentIndex, argument ->
            if (argumentIndex > 0) sb.append(",")
            sb.append("\"").append(argument.esc()).append("\"")
        }
        sb.append("]")
        sb.append(",\"status\":\"")
        sb.append(card.status.name)
        sb.append("\"")
        sb.append(",\"isRisk\":")
        sb.append(card.status.name == "Risk")
        sb.append(",\"visual\":{")
        sb.append("\"kind\":\"").append(card.visual.kind.name).append("\"")
        card.visual.primaryValue?.let { sb.append(",\"primaryValue\":\"").append(it.esc()).append("\"") }
        card.visual.primaryUnit?.let { sb.append(",\"primaryUnitKey\":\"").append(it.key.esc()).append("\"") }
        card.visual.secondaryValue?.let { sb.append(",\"secondaryValue\":\"").append(it.esc()).append("\"") }
        card.visual.secondaryUnit?.let { sb.append(",\"secondaryUnitKey\":\"").append(it.key.esc()).append("\"") }
        card.visual.caption?.let { spec ->
            sb.append(",\"captionKey\":\"").append(spec.key.esc()).append("\",\"captionArgs\":[")
            spec.arguments.forEachIndexed { i, arg -> if (i > 0) sb.append(","); sb.append("\"").append(arg.esc()).append("\"") }
            sb.append("]")
        }
        card.visual.detail?.let { spec ->
            sb.append(",\"detailKey\":\"").append(spec.key.esc()).append("\",\"detailArgs\":[")
            spec.arguments.forEachIndexed { i, arg -> if (i > 0) sb.append(","); sb.append("\"").append(arg.esc()).append("\"") }
            sb.append("]")
        }
        card.visual.footer?.let { spec ->
            sb.append(",\"footerKey\":\"").append(spec.key.esc()).append("\",\"footerArgs\":[")
            spec.arguments.forEachIndexed { i, arg -> if (i > 0) sb.append(","); sb.append("\"").append(arg.esc()).append("\"") }
            sb.append("]")
        }
        card.visual.progress?.let { sb.append(",\"progress\":").append(it) }
        card.visual.highlightedIndex?.let { sb.append(",\"highlightedIndex\":").append(it) }
        sb.append(",\"weeklyDayPlans\":[")
        card.visual.weeklyDayPlans.forEachIndexed { i, plan ->
            if (i > 0) sb.append(",")
            sb.append("{\"dayIndex\":").append(plan.dayIndex)
            plan.workoutName?.let { sb.append(",\"workoutNameKey\":\"").append(it.key.esc()).append("\"") }
            plan.workoutDurationMinutes?.let { sb.append(",\"workoutDurationMinutes\":").append(it) }
            plan.workoutTrainingLoad?.let { sb.append(",\"workoutTrainingLoad\":").append(it) }
            sb.append("}")
        }
        sb.append("]")
        sb.append(",\"chartPoints\":[")
        card.visual.chartPoints.forEachIndexed { i, point ->
            if (i > 0) sb.append(",")
            sb.append("{\"label\":\"").append(point.label.esc()).append("\",\"value\":").append(point.value)
                .append(",\"level\":\"").append(point.level.name).append("\"")
            point.minimum?.let { sb.append(",\"minimum\":").append(it) }
            point.maximum?.let { sb.append(",\"maximum\":").append(it) }
            point.average?.let { sb.append(",\"average\":").append(it) }
            sb.append("}")
        }
        sb.append("],\"metrics\":[")
        card.visual.metrics.forEachIndexed { i, metric ->
            if (i > 0) sb.append(",")
            sb.append("{\"labelKey\":\"").append(metric.label.key.esc()).append("\",\"value\":\"").append(metric.value.esc()).append("\"")
            metric.unit?.let { sb.append(",\"unitKey\":\"").append(it.key.esc()).append("\"") }
            sb.append("}")
        }
        sb.append("]")
        sb.append(",\"highlightedBodyRegions\":[")
        card.visual.highlightedBodyRegions.forEachIndexed { i, region ->
            if (i > 0) sb.append(",")
            sb.append("\"").append(region.esc()).append("\"")
        }
        sb.append("]")
        card.visual.range?.let { range ->
            sb.append(",\"range\":{\"minimum\":").append(range.minimum).append(",\"maximum\":").append(range.maximum)
                .append(",\"current\":").append(range.current)
            range.normalMin?.let { sb.append(",\"normalMin\":").append(it) }
            range.normalMax?.let { sb.append(",\"normalMax\":").append(it) }
            range.average?.let { sb.append(",\"average\":").append(it) }
            sb.append(",\"segments\":[")
            range.segments.forEachIndexed { index, segment ->
                if (index > 0) sb.append(",")
                sb.append("{\"minimum\":").append(segment.minimum)
                    .append(",\"maximum\":").append(segment.maximum)
                    .append(",\"level\":\"").append(segment.level.name).append("\"}")
            }
            sb.append("]")
            sb.append("}")
        }
        sb.append(",\"sleepStages\":[")
        card.visual.sleepStages.forEachIndexed { i, stage ->
            if (i > 0) sb.append(",")
            sb.append("{\"stage\":\"").append(stage.stage.name).append("\",\"startMinute\":").append(stage.startMinute)
                .append(",\"durationMinutes\":").append(stage.durationMinutes).append("}")
        }
        sb.append("]")
        card.visual.startTime?.let { sb.append(",\"startTime\":\"").append(it.esc()).append("\"") }
        card.visual.endTime?.let { sb.append(",\"endTime\":\"").append(it.esc()).append("\"") }
        card.visual.assetKey?.let { sb.append(",\"assetKey\":\"").append(it.esc()).append("\"") }
        sb.append("}")
        sb.append("}")
    }
    sb.append("],\"enabledTypes\":\"")
    sb.append(state.enabledCardTypes.joinToString(",") { it.name })
    sb.append("\"}")
    return sb.toString()
}

fun String.esc(): String = replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
