using NutriExercise.Core.Entities;

namespace NutriExercise.Tests;

public class EntitySmokeTests
{
    [Fact]
    public void User_Has_Empty_Defaults()
    {
        var user = new User();

        Assert.Equal(string.Empty, user.Name);
        Assert.Equal(string.Empty, user.Email);
    }

    [Fact]
    public void Routine_Has_Empty_Defaults()
    {
        var routine = new Routine();

        Assert.Equal(string.Empty, routine.Name);
        Assert.Equal(string.Empty, routine.DayOfWeek);
    }

    [Fact]
    public void Diet_Has_Empty_Defaults()
    {
        var diet = new Diet();

        Assert.Equal(string.Empty, diet.Name);
        Assert.Equal(string.Empty, diet.MealType);
    }
}
