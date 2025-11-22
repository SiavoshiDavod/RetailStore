public record Mobile(string Value)
{
    public static implicit operator string(Mobile m) => m.Value;
    public static Mobile From(string value) => new(value.NormalizePersianMobile());
}