heatmapColor[t_] := Blend[{Blue, Cyan, Green, Yellow, Red}, Clip[t, {0, 1}]];

maxVal = 250*^6;
bl = BarLegend[{heatmapColor[# / maxVal] &, {0, maxVal}}];
Print["Head of BarLegend: ", Head[bl]];
If[Head[bl] === BarLegend, Print["Syntax OK!"]];
