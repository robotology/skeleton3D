function ax =  set_tight_border(ax)
    k = 1.5;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset;
    left = outerpos(1) + k*ti(1);
    bottom = outerpos(2);% + ti(2);
    ax_width = outerpos(3) - 1.5*k*ti(1);
    ax_height = outerpos(4) - ti(2) - ti(4);
    ax.Position = [left bottom ax_width ax_height];
end