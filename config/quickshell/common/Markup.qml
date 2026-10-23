pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function plain(text) {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function paint(color, text) {
        return `<font color="${Settings[color]}">${text}</font>`;
    }

    function fromAnsi(ansi) {
        const parts = ansi.split(/\x1b\[([0-9;?]*)([A-Za-z])/);
        let out = "";
        let closing = [];
        for (let i = 0; i < parts.length; i += 3) {
            out += plain(parts[i]).replace(/ /g, "&nbsp;").replace(/\n/g, "<br>");
            if (parts[i + 2] !== "m")
                continue;
            const codes = parts[i + 1].split(";");
            if (codes[0] === "" || codes[0] === "0") {
                out += closing.reverse().join("");
                closing = [];
            } else if (codes[0] === "1") {
                out += "<b>";
                closing.push("</b>");
            } else if (codes[0] === "38" && codes[1] === "2") {
                const hex = codes.slice(2, 5).map(c => Number(c).toString(16).padStart(2, "0")).join("");
                out += `<font color="#${hex}">`;
                closing.push("</font>");
            }
        }
        return out + closing.reverse().join("");
    }
}
