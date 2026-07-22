function SelectorRange = setSelectorFrequencyRange(Range)
arguments
    Range (1,2) double
end
mustBeLessThan(Range(1),Range(2));

if Range(1) <= 0
    Range(1) = Range(2)*1e-4;
end
Lrange = log10(Range);
Logdiff = diff(Lrange);
SelectorRange = 10.^(Lrange(1)+[Logdiff Logdiff*2]/3);

end

