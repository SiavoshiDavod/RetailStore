# مرحله ۱: بیس برای ران تایم
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# مرحله ۲: بیس برای بیلد
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# کپی فایل‌های پروژه و ریستور
COPY ["src/AuthService/AuthService.Api/AuthService.Api.csproj", "src/AuthService/AuthService.Api/"]
COPY ["src/AuthService/AuthService.Application/AuthService.Application.csproj", "src/AuthService/AuthService.Application/"]
COPY ["src/AuthService/AuthService.Domain/AuthService.Domain.csproj", "src/AuthService/AuthService.Domain/"]
COPY ["src/AuthService/AuthService.Infrastructure/AuthService.Infrastructure.csproj", "src/AuthService/AuthService.Infrastructure/"]

RUN dotnet restore "src/AuthService/AuthService.Api/AuthService.Api.csproj"

# کپی بقیه کدها
COPY . .

# بیلد و پابلیش
WORKDIR "/src/src/AuthService/AuthService.Api"
RUN dotnet publish "AuthService.Api.csproj" -c Release -o /app/publish --no-restore

# مرحله نهایی
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "AuthService.Api.dll"]