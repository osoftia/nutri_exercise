using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutriExercise.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDailyLogAndRlTraceTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AiTrainingTraces",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModelName = table.Column<string>(type: "text", nullable: false),
                    PromptUsed = table.Column<string>(type: "text", nullable: false),
                    UserRawText = table.Column<string>(type: "text", nullable: false),
                    AiPredictedJson = table.Column<string>(type: "text", nullable: false),
                    WasCorrectedByHuman = table.Column<bool>(type: "boolean", nullable: false),
                    HumanFinalJson = table.Column<string>(type: "text", nullable: true),
                    ExecutionTimeMs = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AiTrainingTraces", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DailyLogRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    OriginalText = table.Column<string>(type: "text", nullable: false),
                    Calories = table.Column<int>(type: "integer", nullable: false),
                    Protein = table.Column<int>(type: "integer", nullable: false),
                    Carbs = table.Column<int>(type: "integer", nullable: false),
                    Fats = table.Column<int>(type: "integer", nullable: false),
                    MuscleGroups = table.Column<string>(type: "text", nullable: false),
                    TraceId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyLogRecords", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AiTrainingTraces");

            migrationBuilder.DropTable(
                name: "DailyLogRecords");
        }
    }
}
