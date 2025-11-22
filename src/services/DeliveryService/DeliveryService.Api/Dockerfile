FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore "src/DeliveryService/DeliveryService.Api/DeliveryService.Api.csproj"
RUN dotnet publish "src/DeliveryService/DeliveryService.Api/DeliveryService.Api.csproj" -c Release -o /app/publish --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "DeliveryService.Api.dll"]