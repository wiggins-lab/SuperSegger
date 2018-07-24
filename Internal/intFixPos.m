function x = intFixPos( x, ss )


if x(1) < 1
    x(1) = 1;
elseif x(1) > ss(2)
    x(1) = ss(2);
end

if x(2) < 1
    x(2) = 1;
elseif x(2) > ss(1)
    x(2) = ss(1);
end


end
