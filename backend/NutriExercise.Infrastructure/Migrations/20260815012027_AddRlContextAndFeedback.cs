using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutriExercise.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddRlContextAndFeedback : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsCorrect",
                table: "AiInteractions",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UsedContext",
                table: "AiInteractions",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsCorrect",
                table: "AiInteractions");

            migrationBuilder.DropColumn(
                name: "UsedContext",
                table: "AiInteractions");
        }
    }
}
