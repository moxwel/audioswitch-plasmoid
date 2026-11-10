.pragma library

const FALLBACK_ICON = "audio-headphones";

function withoutSymbolic(iconName) {
    return iconName.replace(/-symbolic$/, "");
}

function systemIconFor(reportedIcon, formFactorIcon) {
    return withoutSymbolic(reportedIcon || formFactorIcon) || FALLBACK_ICON;
}
