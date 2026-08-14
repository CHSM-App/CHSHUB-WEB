<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="landing_page.aspx.cs" Inherits="Society2024.landing_page" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>CHS Society - Modern Society Management</title>
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #1a202c;
            background: #ffffff;
            overflow-x: hidden;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }

        /* Enhanced Animated Background */
        .animated-bg {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 0;
            background: linear-gradient(135deg, #fff5f5 0%, #ffffff 50%, #fff0f0 100%);
            animation: bgPulse 15s ease-in-out infinite;
        }

        @keyframes bgPulse {
            0%, 100% { background: linear-gradient(135deg, #fff5f5 0%, #ffffff 50%, #fff0f0 100%); }
            50% { background: linear-gradient(135deg, #fff0f0 0%, #fff5f5 50%, #ffffff 100%); }
        }

        /* Floating Particles */
        .particles {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 1;
            pointer-events: none;
            overflow: hidden;
        }

        .particle {
            position: absolute;
            width: 4px;
            height: 4px;
            background: radial-gradient(circle, #ff6b6b, #D40000);
            border-radius: 50%;
            opacity: 0.6;
            animation: float-up 15s linear infinite;
        }

        @keyframes float-up {
            0% {
                transform: translateY(100vh) scale(0);
                opacity: 0;
            }
            10% {
                opacity: 0.6;
            }
            90% {
                opacity: 0.6;
            }
            100% {
                transform: translateY(-100px) scale(1);
                opacity: 0;
            }
        }

        /* Enhanced Floating Shapes with 3D effect */
        .floating-shapes {
            position: fixed;
            width: 100%;
            height: 100%;
            z-index: 1;
            pointer-events: none;
            overflow: hidden;
        }

        .shape {
            position: absolute;
            opacity: 0.15;
            filter: blur(1px);
        }

        .shape-circle {
            width: 150px;
            height: 150px;
            background: linear-gradient(135deg, #D40000, #ff4444);
            border-radius: 50%;
            animation: float-circle 20s infinite ease-in-out;
            box-shadow: 0 10px 40px rgba(212, 0, 0, 0.3);
        }

        .shape-square {
            width: 100px;
            height: 100px;
            background: linear-gradient(135deg, #ff6b6b, #D40000);
            border-radius: 20px;
            animation: float-square 25s infinite ease-in-out;
            transform: rotate(45deg);
            box-shadow: 0 10px 40px rgba(212, 0, 0, 0.3);
        }

        .shape-triangle {
            width: 0;
            height: 0;
            border-left: 75px solid transparent;
            border-right: 75px solid transparent;
            border-bottom: 130px solid #D40000;
            animation: float-triangle 30s infinite ease-in-out;
            filter: drop-shadow(0 10px 40px rgba(212, 0, 0, 0.3));
        }

        .shape-hexagon {
            width: 100px;
            height: 57.74px;
            background: linear-gradient(135deg, #ff4444, #D40000);
            position: relative;
            animation: float-hexagon 22s infinite ease-in-out;
        }

        .shape-hexagon:before,
        .shape-hexagon:after {
            content: "";
            position: absolute;
            width: 0;
            border-left: 50px solid transparent;
            border-right: 50px solid transparent;
        }

        .shape-hexagon:before {
            bottom: 100%;
            border-bottom: 28.87px solid #ff4444;
        }

        .shape-hexagon:after {
            top: 100%;
            border-top: 28.87px solid #D40000;
        }

        .shape-1 { top: 10%; left: 10%; animation-delay: 0s; }
        .shape-2 { top: 60%; left: 80%; animation-delay: 5s; }
        .shape-3 { top: 30%; left: 70%; animation-delay: 3s; }
        .shape-4 { top: 70%; left: 20%; animation-delay: 7s; }
        .shape-5 { top: 50%; left: 50%; animation-delay: 2s; }
        .shape-6 { top: 20%; left: 85%; animation-delay: 4s; }

        @keyframes float-circle {
            0%, 100% { 
                transform: translate(0, 0) scale(1) rotate(0deg); 
            }
            25% { 
                transform: translate(50px, -50px) scale(1.2) rotate(90deg); 
            }
            50% { 
                transform: translate(-30px, -80px) scale(0.9) rotate(180deg); 
            }
            75% { 
                transform: translate(40px, -40px) scale(1.1) rotate(270deg); 
            }
        }

        @keyframes float-square {
            0%, 100% { 
                transform: translate(0, 0) rotate(45deg) scale(1); 
            }
            33% { 
                transform: translate(-40px, 60px) rotate(135deg) scale(1.1); 
            }
            66% { 
                transform: translate(60px, -40px) rotate(225deg) scale(0.9); 
            }
        }

        @keyframes float-triangle {
            0%, 100% { 
                transform: translate(0, 0) rotate(0deg); 
            }
            50% { 
                transform: translate(-60px, 80px) rotate(180deg); 
            }
        }

        @keyframes float-hexagon {
            0%, 100% { 
                transform: translate(0, 0) rotate(0deg) scale(1); 
            }
            33% { 
                transform: translate(40px, -60px) rotate(120deg) scale(1.1); 
            }
            66% { 
                transform: translate(-50px, 40px) rotate(240deg) scale(0.9); 
            }
        }

        /* Animated Building Icons Background */
        .buildings-background {
            position: absolute;
            bottom: 0;
            left: 0;
            width: 200%;
            height: 200px;
            z-index: 0;
            opacity: 0.08;
            animation: moveBuildings 60s linear infinite;
        }

        @keyframes moveBuildings {
            0% { transform: translateX(0); }
            100% { transform: translateX(-50%); }
        }

        .building-icon {
            display: inline-block;
            font-size: 100px;
            margin: 0 50px;
            filter: grayscale(1);
            animation: buildingBounce 3s ease-in-out infinite;
        }

        .building-icon:nth-child(odd) {
            animation-delay: 0.5s;
        }

        @keyframes buildingBounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }

        /* Enhanced Header with Glassmorphism */
        header {
            background: rgba(255, 255, 255, 0.85);
            backdrop-filter: blur(20px);
            position: fixed;
            top: 0;
            width: 100%;
            z-index: 1000;
            box-shadow: 0 4px 30px rgba(212, 0, 0, 0.1);
            border-bottom: 1px solid rgba(212, 0, 0, 0.1);
            transition: all 0.3s ease;
            animation: slideDown 0.5s ease-out;
        }

        @keyframes slideDown {
            from {
                transform: translateY(-100%);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        header.scrolled {
            background: rgba(255, 255, 255, 0.95);
            box-shadow: 0 4px 30px rgba(212, 0, 0, 0.2);
        }

        nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1.2rem 0;
        }

        .logo {
            font-size: 2.5rem;
            font-weight: 800;
            background: linear-gradient(135deg, #ff4444 0%, #D40000 50%, #8b0000 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            letter-spacing: -1px;
            position: relative;
            animation: glow 3s ease-in-out infinite, logoFloat 4s ease-in-out infinite;
            cursor: pointer;
            transition: transform 0.3s ease;
        }

        .logo:hover {
            transform: scale(1.05) rotate(-2deg);
        }

        @keyframes glow {
            0%, 100% { filter: drop-shadow(0 0 10px rgba(212, 0, 0, 0.3)); }
            50% { filter: drop-shadow(0 0 20px rgba(212, 0, 0, 0.5)); }
        }

        @keyframes logoFloat {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-5px); }
        }

        .nav-links {
            display: flex;
            list-style: none;
            gap: 2.5rem;
            align-items: center;
        }

        .nav-links a {
            text-decoration: none;
            color: #4a5568;
            font-weight: 600;
            font-size: 0.95rem;
            transition: all 0.3s ease;
            position: relative;
        }

        .nav-links a::after {
            content: '';
            position: absolute;
            bottom: -5px;
            left: 0;
            width: 0;
            height: 2px;
            background: linear-gradient(90deg, #D40000, #ff4444);
            transition: width 0.3s ease;
        }

        .nav-links a:hover {
            color: #D40000;
            transform: translateY(-2px);
        }

        .nav-links a:hover::after {
            width: 100%;
        }

        .cta-button {
            background: linear-gradient(135deg, #D40000 0%, #8b0000 100%);
            color: white;
            padding: 12px 28px;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            font-size: 0.9rem;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(212, 0, 0, 0.3);
            position: relative;
            overflow: hidden;
            animation: pulse 2s ease-in-out infinite;
        }

        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }

        .cta-button::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
            transition: left 0.5s;
        }

        .cta-button:hover::before {
            left: 100%;
        }

        .cta-button:hover {
            transform: translateY(-2px) scale(1.05);
            box-shadow: 0 6px 25px rgba(212, 0, 0, 0.5);
            animation: none;
        }

        /* Enhanced Hero Section */
        .hero {
            padding: 180px 0 120px;
            min-height: 100vh;
            position: relative;
            z-index: 2;
            display: flex;
            align-items: center;
            background: linear-gradient(135deg, #fff5f5 0%, #ffffff 50%, #fff8f8 100%);
            overflow: hidden;
        }

        .hero::before {
            content: '';
            position: absolute;
            top: 0;
            right: 0;
            width: 50%;
            height: 100%;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="%23D40000" stroke-width="0.2"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>') repeat;
            opacity: 0.1;
            animation: gridMove 20s linear infinite;
        }

        @keyframes gridMove {
            0% { transform: translate(0, 0); }
            100% { transform: translate(10px, 10px); }
        }

        .hero-content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 6rem;
            align-items: center;
            position: relative;
            z-index: 1;
            max-width: 1400px;
            margin: 0 auto;
        }

        .hero-text {
            opacity: 0;
            animation: fadeInUp 1s ease forwards 0.3s;
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(50px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .hero-text h1 {
            font-size: 4.5rem;
            font-weight: 800;
            color: #1a202c;
            margin-bottom: 2rem;
            line-height: 1.1;
            letter-spacing: -0.03em;
        }

        .hero-text .highlight {
            background: linear-gradient(135deg, #ff6b6b 0%, #D40000 50%, #ff4444 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            position: relative;
            display: inline-block;
            animation: textShine 3s ease-in-out infinite;
        }

        @keyframes textShine {
            0%, 100% {
                background-position: 0% 50%;
            }
            50% {
                background-position: 100% 50%;
            }
        }

        .hero-text .highlight::after {
            content: '';
            position: absolute;
            bottom: -10px;
            left: 0;
            width: 100%;
            height: 4px;
            background: linear-gradient(90deg, transparent, #D40000, transparent);
            animation: shimmer 2s infinite;
        }

        @keyframes shimmer {
            0%, 100% { opacity: 0.3; transform: scaleX(0.5); }
            50% { opacity: 1; transform: scaleX(1); }
        }

        .hero-text p {
            font-size: 1.25rem;
            color: #4a5568;
            margin-bottom: 3rem;
            line-height: 1.8;
            font-weight: 400;
            animation: fadeIn 1s ease forwards 0.5s;
            opacity: 0;
        }

        @keyframes fadeIn {
            to { opacity: 1; }
        }

        .hero-buttons {
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            animation: fadeInUp 1s ease forwards 0.7s;
            opacity: 0;
        }

        .btn-primary {
            background: linear-gradient(135deg, #D40000 0%, #8b0000 100%);
            color: white;
            padding: 18px 36px;
            border: none;
            border-radius: 14px;
            font-size: 1.05rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 8px 30px rgba(212, 0, 0, 0.3);
            display: inline-flex;
            align-items: center;
            gap: 10px;
            position: relative;
            overflow: hidden;
        }

        .btn-primary::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
            transition: left 0.5s;
        }

        .btn-primary:hover::before {
            left: 100%;
        }

        .btn-primary:hover {
            transform: translateY(-3px) scale(1.02);
            box-shadow: 0 12px 40px rgba(212, 0, 0, 0.5);
        }

        .btn-secondary {
            background: white;
            color: #D40000;
            padding: 18px 36px;
            border: 2px solid #D40000;
            border-radius: 14px;
            font-size: 1.05rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .btn-secondary::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: #D40000;
            transition: width 0.4s, height 0.4s, top 0.4s, left 0.4s;
            transform: translate(-50%, -50%);
            z-index: -1;
        }

        .btn-secondary:hover::before {
            width: 300px;
            height: 300px;
        }

        .btn-secondary:hover {
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(212, 0, 0, 0.3);
        }

        .hero-visual {
            position: relative;
            opacity: 0;
            animation: fadeInRight 1s ease forwards 0.5s;
        }

        @keyframes fadeInRight {
            from {
                opacity: 0;
                transform: translateX(50px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        /* Enhanced Dashboard Preview with 3D effect */
        .dashboard-preview {
            background: white;
            border-radius: 24px;
            box-shadow: 
                0 20px 60px rgba(212, 0, 0, 0.15),
                0 0 0 1px rgba(212, 0, 0, 0.05);
            border: 1px solid rgba(212, 0, 0, 0.1);
            padding: 2.5rem;
            position: relative;
            overflow: hidden;
            transition: all 0.5s ease;
            animation: float 6s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0) rotateY(0deg); }
            50% { transform: translateY(-20px) rotateY(5deg); }
        }

        .dashboard-preview::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(212, 0, 0, 0.05) 0%, transparent 70%);
            animation: rotate 20s linear infinite;
        }

        @keyframes rotate {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .dashboard-preview:hover {
            transform: translateY(-10px) scale(1.02);
            box-shadow: 
                0 30px 80px rgba(212, 0, 0, 0.2),
                0 0 0 1px rgba(212, 0, 0, 0.1);
            animation: none;
        }

        .dashboard-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid #f1f5f9;
            position: relative;
            z-index: 1;
        }

        .dashboard-icon {
            width: 48px;
            height: 48px;
            background: linear-gradient(135deg, rgba(212, 0, 0, 0.1), rgba(212, 0, 0, 0.05));
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            border: 1px solid rgba(212, 0, 0, 0.2);
            animation: iconSpin 10s linear infinite;
        }

        @keyframes iconSpin {
            0%, 90%, 100% { transform: rotate(0deg); }
            95% { transform: rotate(360deg); }
        }

        .dashboard-title {
            color: #1a202c;
            font-size: 1.25rem;
            font-weight: 600;
        }

        .stats-cards {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
            margin-bottom: 1.5rem;
            position: relative;
            z-index: 1;
        }

        .stat-card {
            background: linear-gradient(135deg, #fff5f5, #ffffff);
            padding: 1.5rem;
            border-radius: 16px;
            border: 1px solid #fee;
            position: relative;
            overflow: hidden;
            transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
            animation: cardPop 0.5s ease-out backwards;
            will-change: transform;
        }

        @keyframes cardPop {
            from {
                opacity: 0;
                transform: scale(0.8);
            }
            to {
                opacity: 1;
                transform: scale(1);
            }
        }

        .stat-card:nth-child(1) { animation-delay: 0.1s; }
        .stat-card:nth-child(2) { animation-delay: 0.2s; }
        .stat-card:nth-child(3) { animation-delay: 0.3s; }
        .stat-card:nth-child(4) { animation-delay: 0.4s; }

        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, transparent, rgba(212, 0, 0, 0.05));
            opacity: 0;
            transition: opacity 0.5s ease;
        }

        .stat-card:hover {
            transform: translateY(-4px) scale(1.02);
            border-color: rgba(212, 0, 0, 0.3);
            box-shadow: 0 8px 25px rgba(212, 0, 0, 0.1);
        }

        .stat-card:hover::before {
            opacity: 1;
        }

        .stat-card.due-payments {
            background: linear-gradient(135deg, #fef2f2, #ffffff);
            border-color: #fecaca;
        }

        .stat-card.defaulters {
            background: linear-gradient(135deg, #f0fdf4, #ffffff);
            border-color: #bbf7d0;
        }

        .stat-card.members {
            background: linear-gradient(135deg, #fefce8, #ffffff);
            border-color: #fde047;
        }

        .stat-card.income {
            background: linear-gradient(135deg, #f0f9ff, #ffffff);
            border-color: #bae6fd;
        }

        .stat-value {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 0.25rem;
            color: #1a202c;
            animation: countUp 2s ease-out;
        }

        @keyframes countUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .stat-card.due-payments .stat-value {
            color: #dc2626;
        }

        .stat-card.defaulters .stat-value {
            color: #16a34a;
        }

        .stat-card.members .stat-value {
            color: #ca8a04;
        }

        .stat-card.income .stat-value {
            color: #2563eb;
        }

        .stat-label {
            color: #64748b;
            font-size: 0.75rem;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .chart-area {
            background: linear-gradient(135deg, #fff5f5, #ffffff);
            height: 140px;
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
            border: 1px solid #fee;
            z-index: 1;
        }

        .chart-bars {
            display: flex;
            align-items: end;
            gap: 6px;
            height: 70px;
        }

        .chart-bar {
            width: 8px;
            background: linear-gradient(to top, #D40000, #ff4444);
            border-radius: 4px 4px 0 0;
            opacity: 0;
            animation: growBar 1.5s ease-out forwards;
            box-shadow: 0 0 15px rgba(212, 0, 0, 0.3);
            transition: all 0.3s ease;
        }

        .chart-bar:hover {
            transform: scaleY(1.1);
            box-shadow: 0 0 25px rgba(212, 0, 0, 0.5);
        }

        .chart-bar:nth-child(1) { height: 20px; animation-delay: 0.8s; }
        .chart-bar:nth-child(2) { height: 35px; animation-delay: 0.9s; }
        .chart-bar:nth-child(3) { height: 50px; animation-delay: 1s; }
        .chart-bar:nth-child(4) { height: 28px; animation-delay: 1.1s; }
        .chart-bar:nth-child(5) { height: 42px; animation-delay: 1.2s; }
        .chart-bar:nth-child(6) { height: 25px; animation-delay: 1.3s; }
        .chart-bar:nth-child(7) { height: 38px; animation-delay: 1.4s; }

        @keyframes growBar {
            from { 
                opacity: 0;
                transform: scaleY(0);
            }
            to { 
                opacity: 1;
                transform: scaleY(1);
            }
        }

        /* Stats Section with enhanced animations */
        .stats {
            padding: 120px 0;
            background: linear-gradient(135deg, #fff5f5 0%, #ffffff 100%);
            position: relative;
            z-index: 2;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 3rem;
            text-align: center;
        }

        .stat-item {
            opacity: 0;
            transform: translateY(30px);
            transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
            padding: 2rem;
            background: white;
            border-radius: 20px;
            box-shadow: 0 4px 20px rgba(212, 0, 0, 0.1);
            position: relative;
            overflow: hidden;
            will-change: transform;
        }

        .stat-item::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(212, 0, 0, 0.1) 0%, transparent 70%);
            opacity: 0;
            transition: opacity 0.6s ease;
        }

        .stat-item:hover::before {
            opacity: 1;
            animation: rotate 10s linear infinite;
        }

        .stat-item.visible {
            opacity: 1;
            transform: translateY(0);
        }

        .stat-item:hover {
            transform: translateY(-10px) scale(1.03);
            box-shadow: 0 12px 40px rgba(212, 0, 0, 0.2);
        }

        .stat-item h3 {
            font-size: 3.5rem;
            font-weight: 800;
            margin-bottom: 0.5rem;
            background: linear-gradient(135deg, #ff4444, #D40000);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            position: relative;
            z-index: 1;
        }

        .stat-item p {
            color: #4a5568;
            font-size: 1.1rem;
            font-weight: 500;
            position: relative;
            z-index: 1;
        }

        /* Features Section with enhanced cards */
        .features {
            padding: 120px 0;
            background: white;
            position: relative;
            z-index: 2;
        }

        .section-header {
            text-align: center;
            margin-bottom: 5rem;
            opacity: 0;
            transform: translateY(30px);
            transition: all 0.8s ease;
        }

        .section-header.visible {
            opacity: 1;
            transform: translateY(0);
        }

        .section-header h2 {
            font-size: 3rem;
            font-weight: 800;
            color: #1a202c;
            margin-bottom: 1rem;
            position: relative;
            display: inline-block;
        }

        .section-header h2::after {
            content: '';
            position: absolute;
            bottom: -10px;
            left: 50%;
            transform: translateX(-50%);
            width: 100px;
            height: 4px;
            background: linear-gradient(90deg, transparent, #D40000, transparent);
            animation: expandLine 2s ease-in-out infinite;
        }

        @keyframes expandLine {
            0%, 100% { width: 100px; }
            50% { width: 150px; }
        }

        .section-header p {
            font-size: 1.25rem;
            color: #4a5568;
            max-width: 600px;
            margin: 0 auto;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 2rem;
            margin-top: 3rem;
        }

        .feature-card {
            background: white;
            padding: 2.5rem;
            border-radius: 20px;
            box-shadow: 0 4px 20px rgba(212, 0, 0, 0.1);
            border: 1px solid #fee;
            transition: all 0.6s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
            opacity: 0;
            transform: translateY(30px);
            will-change: transform;
        }

        .feature-card.visible {
            opacity: 1;
            transform: translateY(0);
        }

        .feature-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, transparent, rgba(212, 0, 0, 0.05));
            opacity: 0;
            transition: opacity 0.6s ease;
        }

        .feature-card::after {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255, 68, 68, 0.1) 0%, transparent 70%);
            opacity: 0;
            transition: all 0.8s ease;
        }

        .feature-card:hover {
            transform: translateY(-8px) scale(1.02);
            box-shadow: 0 12px 40px rgba(212, 0, 0, 0.2);
            border-color: rgba(212, 0, 0, 0.3);
        }

        .feature-card:hover::before {
            opacity: 1;
        }

        .feature-card:hover::after {
            opacity: 1;
            animation: rotate 8s linear infinite;
        }

        .feature-icon {
            font-size: 3rem;
            margin-bottom: 1.5rem;
            display: block;
            filter: drop-shadow(0 0 20px rgba(212, 0, 0, 0.3));
            transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            z-index: 1;
            will-change: transform;
        }

        .feature-card:hover .feature-icon {
            transform: scale(1.15) rotate(5deg);
        }

        .feature-card h3 {
            font-size: 1.4rem;
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 1rem;
            position: relative;
            z-index: 1;
        }

        .feature-card p {
            color: #4a5568;
            line-height: 1.7;
            font-size: 1rem;
            position: relative;
            z-index: 1;
        }

        /* Building Showcase with parallax effect */
        .building-showcase {
            padding: 120px 0;
            position: relative;
            z-index: 2;
            overflow: hidden;
            background: linear-gradient(135deg, #fff8f8 0%, #ffffff 100%);
        }

        .building-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 2rem;
            margin-top: 3rem;
        }

        .building-card {
            position: relative;
            height: 400px;
            border-radius: 20px;
            overflow: hidden;
            opacity: 0;
            transform: scale(0.9);
            transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
            background: #f8f9fa;
            border: 2px solid #fee;
            display: flex;
            align-items: center;
            justify-content: center;
            will-change: transform, opacity;
        }

        .building-card.visible {
            opacity: 1;
            transform: scale(1);
        }

        .building-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, rgba(212, 0, 0, 0.05), transparent);
            opacity: 0;
            transition: opacity 0.6s ease;
        }

        .building-placeholder {
            font-size: 6rem;
            opacity: 0.3;
            text-align: center;
            transition: all 0.6s cubic-bezier(0.4, 0, 0.2, 1);
            will-change: transform;
        }

        .building-card:hover .building-placeholder {
            transform: scale(1.15) rotate(5deg);
            opacity: 0.5;
        }

        .building-placeholder-text {
            position: absolute;
            bottom: 2rem;
            left: 2rem;
            right: 2rem;
            z-index: 2;
            transform: translateY(20px);
            opacity: 0;
            transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .building-card:hover .building-placeholder-text {
            transform: translateY(0);
            opacity: 1;
        }

        .building-placeholder-text h4 {
            color: #1a202c;
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
        }

        .building-placeholder-text p {
            color: #4a5568;
            font-size: 0.95rem;
        }

        .building-card:hover {
            transform: scale(1.02) translateY(-10px);
            box-shadow: 0 12px 40px rgba(212, 0, 0, 0.2);
            border-color: rgba(212, 0, 0, 0.3);
        }

        .building-card:hover::before {
            opacity: 1;
        }

        /* Mobile App Section with enhanced animations */
        .mobile-app {
            padding: 120px 0;
            background: white;
            position: relative;
            z-index: 2;
        }

        .app-content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 5rem;
            align-items: center;
        }

        .app-text {
            opacity: 0;
            transform: translateX(-30px);
            transition: all 0.8s ease;
        }

        .app-text.visible {
            opacity: 1;
            transform: translateX(0);
        }

        .app-text h2 {
            font-size: 2.75rem;
            font-weight: 800;
            color: #1a202c;
            margin-bottom: 1.5rem;
        }

        .app-text p {
            font-size: 1.2rem;
            color: #4a5568;
            margin-bottom: 2.5rem;
        }

        .app-features {
            list-style: none;
            margin: 2.5rem 0;
        }

        .app-features li {
            padding: 1rem 0;
            display: flex;
            align-items: center;
            gap: 1rem;
            font-size: 1.05rem;
            color: #1a202c;
            opacity: 0;
            transform: translateX(-20px);
            transition: all 0.4s ease;
        }

        .app-features li.visible {
            opacity: 1;
            transform: translateX(0);
        }

        .app-features li::before {
            content: "✓";
            background: linear-gradient(135deg, #D40000, #ff4444);
            color: white;
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 0.9rem;
            flex-shrink: 0;
            box-shadow: 0 4px 15px rgba(212, 0, 0, 0.3);
            animation: checkPulse 2s ease-in-out infinite;
        }

        @keyframes checkPulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
        }

        .app-features li:hover::before {
            animation: checkSpin 0.5s ease;
        }

        @keyframes checkSpin {
            from { transform: rotate(0deg) scale(1); }
            to { transform: rotate(360deg) scale(1.2); }
        }

        .app-visual {
            text-align: center;
            opacity: 0;
            transform: translateX(30px);
            transition: all 0.8s ease;
        }

        .app-visual.visible {
            opacity: 1;
            transform: translateX(0);
        }

        .phone-mockup {
            background: linear-gradient(135deg, #fff5f5, #ffffff);
            padding: 3rem;
            border-radius: 24px;
            box-shadow: 0 20px 60px rgba(212, 0, 0, 0.2);
            display: inline-block;
            border: 2px solid rgba(212, 0, 0, 0.2);
            position: relative;
            overflow: hidden;
            transition: all 0.5s ease;
        }

        .phone-mockup::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(212, 0, 0, 0.05) 0%, transparent 70%);
            animation: rotate 15s linear infinite;
        }

        .phone-mockup:hover {
            transform: scale(1.05) rotateY(10deg);
            box-shadow: 0 30px 80px rgba(212, 0, 0, 0.3);
        }

        .phone-mockup .icon {
            font-size: 8rem;
            position: relative;
            z-index: 1;
            filter: drop-shadow(0 0 30px rgba(212, 0, 0, 0.4));
            animation: phoneFloat 3s ease-in-out infinite;
        }

        @keyframes phoneFloat {
            0%, 100% { transform: translateY(0) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(5deg); }
        }

        .phone-mockup:hover .icon {
            animation: phoneWiggle 0.5s ease;
        }

        @keyframes phoneWiggle {
            0%, 100% { transform: rotate(0deg); }
            25% { transform: rotate(-10deg); }
            75% { transform: rotate(10deg); }
        }

        .phone-mockup h3 {
            color: #1a202c;
            margin-top: 1.5rem;
            font-weight: 700;
            font-size: 1.5rem;
            position: relative;
            z-index: 1;
        }

        .phone-mockup p {
            color: #4a5568;
            font-size: 1rem;
            margin-top: 0.5rem;
            position: relative;
            z-index: 1;
        }

        /* CTA Section with enhanced effects */
        .cta-section {
            padding: 120px 0;
            background: linear-gradient(135deg, #fff0f0 0%, #ffffff 100%);
            position: relative;
            z-index: 2;
            text-align: center;
            overflow: hidden;
        }

        .cta-section::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="%23D40000" stroke-width="0.2"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>') repeat;
            opacity: 0.1;
            animation: gridMove 20s linear infinite;
        }

        .cta-content {
            position: relative;
            z-index: 1;
            opacity: 0;
            transform: translateY(30px);
            transition: all 0.8s ease;
        }

        .cta-content.visible {
            opacity: 1;
            transform: translateY(0);
        }

        .cta-section h2 {
            font-size: 3rem;
            font-weight: 800;
            color: #1a202c;
            margin-bottom: 1.5rem;
            animation: textWave 3s ease-in-out infinite;
        }

        @keyframes textWave {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-5px); }
        }

        .cta-section p {
            font-size: 1.3rem;
            color: #4a5568;
            margin-bottom: 3rem;
        }

        /* Footer */
        footer {
            background: #1a202c;
            color: white;
            padding: 60px 0 30px;
            position: relative;
            z-index: 2;
            border-top: 1px solid rgba(212, 0, 0, 0.1);
        }

        .footer-content {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 3rem;
            margin-bottom: 3rem;
        }

        .footer-section h3 {
            margin-bottom: 1.5rem;
            color: #ffffff;
            font-size: 1.3rem;
            font-weight: 700;
            position: relative;
            display: inline-block;
        }

        .footer-section h3::after {
            content: '';
            position: absolute;
            bottom: -5px;
            left: 0;
            width: 50px;
            height: 2px;
            background: linear-gradient(90deg, #D40000, transparent);
        }

        .footer-section p, .footer-section a {
            color: #94a3b8;
            text-decoration: none;
            font-size: 0.95rem;
            line-height: 2;
            transition: all 0.3s ease;
            display: block;
        }

        .footer-section a:hover {
            color: #ff4444;
            padding-left: 10px;
            transform: translateX(5px);
        }

        .footer-bottom {
            border-top: 1px solid rgba(255, 255, 255, 0.05);
            padding-top: 2rem;
            text-align: center;
            color: #64748b;
        }

        /* Mobile Menu */
        .mobile-menu-toggle {
            display: none;
            flex-direction: column;
            cursor: pointer;
            padding: 8px;
            z-index: 1001;
        }

        .mobile-menu-toggle span {
            width: 28px;
            height: 3px;
            background: #D40000;
            margin: 4px 0;
            transition: 0.4s;
            border-radius: 2px;
        }

        .mobile-menu-toggle.active span:nth-child(1) {
            transform: rotate(-45deg) translate(-6px, 6px);
        }

        .mobile-menu-toggle.active span:nth-child(2) {
            opacity: 0;
        }

        .mobile-menu-toggle.active span:nth-child(3) {
            transform: rotate(45deg) translate(-6px, -6px);
        }

        /* Moving Document Icons */
        .moving-icon {
            position: fixed;
            font-size: 3rem;
            opacity: 0.1;
            animation: moveAround 30s linear infinite;
            z-index: 1;
            pointer-events: none;
            filter: blur(1px);
        }

        .icon-1 { animation-delay: 0s; }
        .icon-2 { animation-delay: 10s; }
        .icon-3 { animation-delay: 20s; }

        @keyframes moveAround {
            0% { top: 10%; left: 10%; transform: rotate(0deg); }
            25% { top: 80%; left: 20%; transform: rotate(90deg); }
            50% { top: 20%; left: 80%; transform: rotate(180deg); }
            75% { top: 70%; left: 70%; transform: rotate(270deg); }
            100% { top: 10%; left: 10%; transform: rotate(360deg); }
        }

        /* Responsive Design */
        @media (max-width: 1024px) {
            .hero-text h1 {
                font-size: 3.5rem;
            }

            .features-grid {
                grid-template-columns: repeat(2, 1fr);
            }

            .building-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 768px) {
            .mobile-menu-toggle {
                display: flex;
            }

            .nav-links {
                position: fixed;
                top: 80px;
                right: -100%;
                width: 100%;
                height: calc(100vh - 80px);
                background: rgba(255, 255, 255, 0.98);
                backdrop-filter: blur(20px);
                flex-direction: column;
                justify-content: flex-start;
                align-items: center;
                padding: 3rem 0;
                transition: right 0.4s ease;
                border-left: 1px solid rgba(212, 0, 0, 0.2);
            }

            .nav-links.active {
                right: 0;
            }

            .nav-links li {
                margin: 1.5rem 0;
            }

            .nav-links a {
                font-size: 1.2rem;
            }

            .hero {
                padding: 140px 0 80px;
                min-height: auto;
            }

            .hero-content {
                grid-template-columns: 1fr;
                gap: 4rem;
                text-align: center;
            }

            .hero-text h1 {
                font-size: 2.5rem;
            }

            .hero-text p {
                font-size: 1.1rem;
            }

            .hero-buttons {
                justify-content: center;
                flex-direction: column;
                align-items: center;
            }

            .btn-primary, .btn-secondary {
                width: 100%;
                max-width: 320px;
                justify-content: center;
            }

            .stats-cards {
                grid-template-columns: 1fr;
            }

            .section-header h2 {
                font-size: 2.25rem;
            }

            .features-grid {
                grid-template-columns: 1fr;
            }

            .building-grid {
                grid-template-columns: 1fr;
            }

            .app-content {
                grid-template-columns: 1fr;
                gap: 3rem;
            }

            .app-text h2 {
                font-size: 2.25rem;
            }

            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 2rem;
            }

            .stat-item h3 {
                font-size: 2.5rem;
            }

            .cta-section h2 {
                font-size: 2rem;
            }

            .features, .mobile-app, .cta-section, .stats, .building-showcase {
                padding: 80px 0;
            }
        }

        @media (max-width: 480px) {
            .hero-text h1 {
                font-size: 2rem;
            }

            .logo {
                font-size: 2rem;
            }

            .stat-value {
                font-size: 1.5rem;
            }

            .section-header h2 {
                font-size: 1.75rem;
            }

            .stats-grid {
                grid-template-columns: 1fr;
            }

            .stat-item h3 {
                font-size: 2rem;
            }

            .building-placeholder {
                font-size: 4rem;
            }
        }

        /* Scroll Reveal Classes */
        .reveal {
            opacity: 0;
            transform: translateY(50px);
            transition: all 0.8s ease;
        }

        .reveal.visible {
            opacity: 1;
            transform: translateY(0);
        }

        .reveal-left {
            opacity: 0;
            transform: translateX(-50px);
            transition: all 0.8s ease;
        }

        .reveal-left.visible {
            opacity: 1;
            transform: translateX(0);
        }

        .reveal-right {
            opacity: 0;
            transform: translateX(50px);
            transition: all 0.8s ease;
        }

        .reveal-right.visible {
            opacity: 1;
            transform: translateX(0);
        }
    </style>

    <style>
        /* Responsive Design */
        @media (max-width: 1200px) {
            .container {
                padding: 0 30px;
            }

            .hero-text h1 {
                font-size: 3.8rem;
            }

            .dashboard-preview {
                padding: 2rem;
            }
        }

        @media (max-width: 1024px) {
            .hero-text h1 {
                font-size: 3.2rem;
            }

            .hero-text p {
                font-size: 1.15rem;
            }

            .features-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 1.5rem;
            }

            .building-grid {
                grid-template-columns: repeat(2, 1fr);
            }

            .app-content {
                gap: 4rem;
            }

            .app-text h2 {
                font-size: 2.5rem;
            }

            .phone-mockup {
                padding: 2.5rem;
            }

            .phone-mockup .icon {
                font-size: 6rem;
            }

            .footer-content {
                grid-template-columns: repeat(2, 1fr);
                gap: 2rem;
            }
        }

        @media (max-width: 768px) {
            .container {
                padding: 0 20px;
            }

            .mobile-menu-toggle {
                display: flex;
            }

            .nav-links {
                position: fixed;
                top: 80px;
                right: -100%;
                width: 100%;
                height: calc(100vh - 80px);
                background: rgba(255, 255, 255, 0.98);
                backdrop-filter: blur(20px);
                flex-direction: column;
                justify-content: flex-start;
                align-items: center;
                padding: 3rem 0;
                transition: right 0.4s ease;
                border-left: 1px solid rgba(212, 0, 0, 0.2);
                z-index: 999;
                overflow-y: auto;
            }

            .nav-links.active {
                right: 0;
                box-shadow: -5px 0 20px rgba(0, 0, 0, 0.1);
            }

            .nav-links li {
                margin: 1.5rem 0;
                width: 100%;
                text-align: center;
            }

            .nav-links a {
                font-size: 1.2rem;
                padding: 0.5rem 2rem;
                display: block;
            }

            .nav-links .cta-button {
                margin-top: 1rem;
                display: inline-block;
                width: auto;
            }

            .hero {
                padding: 140px 0 80px;
                min-height: auto;
            }

            .hero-content {
                grid-template-columns: 1fr;
                gap: 3rem;
                text-align: center;
            }

            .hero-text h1 {
                font-size: 2.5rem;
                line-height: 1.2;
            }

            .hero-text p {
                font-size: 1rem;
                margin-bottom: 2rem;
            }

            .hero-buttons {
                justify-content: center;
                flex-direction: column;
                align-items: center;
                gap: 1rem;
            }

            .btn-primary, .btn-secondary {
                width: 100%;
                max-width: 320px;
                justify-content: center;
                padding: 16px 32px;
                font-size: 1rem;
            }

            .dashboard-preview {
                padding: 2rem;
            }

            .dashboard-header {
                margin-bottom: 1.5rem;
            }

            .stats-cards {
                grid-template-columns: 1fr;
                gap: 1rem;
            }

            .stat-card {
                padding: 1.25rem;
            }

            .stat-value {
                font-size: 1.75rem;
            }

            .chart-area {
                height: 120px;
            }

            .chart-bars {
                height: 60px;
            }

            .section-header h2 {
                font-size: 2.25rem;
            }

            .section-header p {
                font-size: 1.1rem;
            }

            .features-grid {
                grid-template-columns: 1fr;
                gap: 1.5rem;
            }

            .feature-card {
                padding: 2rem;
            }

            .feature-icon {
                font-size: 2.5rem;
                margin-bottom: 1rem;
            }

            .feature-card h3 {
                font-size: 1.25rem;
            }

            .building-grid {
                grid-template-columns: 1fr;
                gap: 1.5rem;
            }

            .building-card {
                height: 300px;
            }

            .building-placeholder {
                font-size: 5rem;
            }

            .app-content {
                grid-template-columns: 1fr;
                gap: 3rem;
            }

            .app-text {
                text-align: center;
            }

            .app-text h2 {
                font-size: 2.25rem;
            }

            .app-text p {
                font-size: 1.1rem;
            }

            .app-features {
                text-align: left;
                max-width: 500px;
                margin: 2rem auto;
            }

            .app-features li {
                font-size: 1rem;
            }

            .app-text > div {
                justify-content: center;
            }

            .phone-mockup {
                padding: 2rem;
                margin: 0 auto;
            }

            .phone-mockup .icon {
                font-size: 5rem;
            }

            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 1.5rem;
            }

            .stat-item {
                padding: 1.5rem;
            }

            .stat-item h3 {
                font-size: 2.5rem;
            }

            .stat-item p {
                font-size: 1rem;
            }

            .cta-section h2 {
                font-size: 2rem;
                padding: 0 1rem;
            }

            .cta-section p {
                font-size: 1.1rem;
                padding: 0 1rem;
            }

            .features, .mobile-app, .cta-section, .stats, .building-showcase {
                padding: 80px 0;
            }

            .footer-content {
                grid-template-columns: 1fr;
                gap: 2rem;
            }

            footer {
                padding: 50px 0 20px;
            }

            .floating-shapes {
                display: none;
            }

            .moving-icon {
                display: none;
            }
        }

        @media (max-width: 480px) {
            .container {
                padding: 0 15px;
            }

            .logo {
                font-size: 1.8rem;
            }

            nav {
                padding: 1rem 0;
            }

            .hero {
                padding: 120px 0 60px;
            }

            .hero-text h1 {
                font-size: 1.9rem;
                margin-bottom: 1.5rem;
            }

            .hero-text p {
                font-size: 0.95rem;
                margin-bottom: 1.5rem;
            }

            .btn-primary, .btn-secondary {
                padding: 14px 28px;
                font-size: 0.95rem;
            }

            .dashboard-preview {
                padding: 1.5rem;
            }

            .dashboard-icon {
                width: 40px;
                height: 40px;
                font-size: 1.25rem;
            }

            .dashboard-title {
                font-size: 1.1rem;
            }

            .stat-value {
                font-size: 1.5rem;
            }

            .stat-label {
                font-size: 0.7rem;
            }

            .chart-area {
                height: 100px;
            }

            .chart-bars {
                height: 50px;
                gap: 4px;
            }

            .chart-bar {
                width: 6px;
            }

            .section-header h2 {
                font-size: 1.75rem;
                margin-bottom: 0.75rem;
            }

            .section-header p {
                font-size: 1rem;
            }

            .section-header {
                margin-bottom: 3rem;
            }

            .stats-grid {
                grid-template-columns: 1fr;
                gap: 1.5rem;
            }

            .stat-item {
                padding: 1.5rem;
            }

            .stat-item h3 {
                font-size: 2rem;
            }

            .stat-item p {
                font-size: 0.95rem;
            }

            .features-grid {
                gap: 1.25rem;
            }

            .feature-card {
                padding: 1.75rem;
            }

            .feature-icon {
                font-size: 2.25rem;
            }

            .feature-card h3 {
                font-size: 1.15rem;
                margin-bottom: 0.75rem;
            }

            .feature-card p {
                font-size: 0.95rem;
            }

            .building-card {
                height: 250px;
            }

            .building-placeholder {
                font-size: 4rem;
            }

            .building-placeholder-text h4 {
                font-size: 1.25rem;
            }

            .building-placeholder-text p {
                font-size: 0.85rem;
            }

            .app-text h2 {
                font-size: 1.9rem;
            }

            .app-text p {
                font-size: 1rem;
            }

            .app-features li {
                font-size: 0.95rem;
                padding: 0.75rem 0;
            }

            .app-features li::before {
                width: 24px;
                height: 24px;
                font-size: 0.8rem;
            }

            .phone-mockup {
                padding: 1.75rem;
            }

            .phone-mockup .icon {
                font-size: 4.5rem;
            }

            .phone-mockup h3 {
                font-size: 1.25rem;
                margin-top: 1rem;
            }

            .phone-mockup p {
                font-size: 0.9rem;
            }

            .cta-section h2 {
                font-size: 1.75rem;
            }

            .cta-section p {
                font-size: 1rem;
                margin-bottom: 2rem;
            }

            .features, .mobile-app, .cta-section, .stats, .building-showcase {
                padding: 60px 0;
            }

            .footer-section h3 {
                font-size: 1.15rem;
                margin-bottom: 1rem;
            }

            .footer-section p,
            .footer-section a {
                font-size: 0.9rem;
            }

            .footer-bottom {
                font-size: 0.85rem;
            }

            .particles {
                display: none;
            }

            .buildings-background {
                opacity: 0.05;
            }

            .building-icon {
                font-size: 60px;
                margin: 0 30px;
            }
        }

        @media (max-width: 360px) {
            .logo {
                font-size: 1.6rem;
            }

            .hero-text h1 {
                font-size: 1.65rem;
            }

            .btn-primary, .btn-secondary {
                padding: 12px 24px;
                font-size: 0.9rem;
            }

            .section-header h2 {
                font-size: 1.5rem;
            }

            .stat-item h3 {
                font-size: 1.75rem;
            }

            .feature-card {
                padding: 1.5rem;
            }

            .cta-section h2 {
                font-size: 1.5rem;
            }
        }
    </style>


</head>
<body>
    <div class="animated-bg"></div>
    
    <!-- Floating Particles -->
    <div class="particles" id="particles"></div>
    
    <!-- Floating Shapes -->
    <div class="floating-shapes">
        <div class="shape shape-circle shape-1"></div>
        <div class="shape shape-square shape-2"></div>
        <div class="shape shape-triangle shape-3"></div>
        <div class="shape shape-circle shape-4"></div>
        <div class="shape shape-hexagon shape-5"></div>
        <div class="shape shape-square shape-6"></div>
    </div>

    <!-- Moving Icons -->
    <div class="moving-icon icon-1">🏢</div>ss
    <div class="moving-icon icon-2">🏠</div>
    <div class="moving-icon icon-3">🏘️</div>

    <header>
        <nav class="container">
            <div class="logo">CHSHub</div>
            <ul class="nav-links">
                <li><a href="#features">Features</a></li>
                <%--<li><a href="#buildings">Showcase</a></li>--%>
                <li><a href="#mobile">Mobile App</a></li>
                <li><a href="#contact">Contact</a></li>
                <li><a href="login1.aspx" style="color:white" class="cta-button">Login</a></li>
            </ul>
            <div class="mobile-menu-toggle">
                <span></span>
                <span></span>
                <span></span>
            </div>
        </nav>
    </header>

    <section class="hero">
        <div class="buildings-background">
            <span class="building-icon">🏢</span>
            <span class="building-icon">🏠</span>
            <span class="building-icon">🏘️</span>
            <span class="building-icon">🏬</span>
            <span class="building-icon">🏢</span>
            <span class="building-icon">🏠</span>
            <span class="building-icon">🏘️</span>
            <span class="building-icon">🏬</span>
            <span class="building-icon">🏢</span>
            <span class="building-icon">🏠</span>
        </div>
        
        <div class="container">
            <div class="hero-content">
                <div class="hero-text">
                    <h1>Modern <span class="highlight">Society Management</span> Made Simple</h1>
                    <p>Streamline your cooperative housing society operations with our comprehensive digital platform. Manage payments, track expenses, handle member communications, and much more.</p>
                    <div class="hero-buttons">
                        <a href="login1.aspx" class="btn-primary">
                            Get Started →
                        </a>
                        <a href="#features" class="btn-secondary">Learn More</a>
                    </div>
                </div>
                <div class="hero-visual">
                    <div class="dashboard-preview">
                        <div class="dashboard-header">
                            <div class="dashboard-icon">📊</div>
                            <div class="dashboard-title">Society Dashboard</div>
                        </div>
                        
                        <div class="stats-cards">
                            <div class="stat-card due-payments">
                                <div class="stat-value">₹84.8k</div>
                                <div class="stat-label">Due Payments</div>
                            </div>
                            <div class="stat-card defaulters">
                                <div class="stat-value">0</div>
                                <div class="stat-label">Defaulters</div>
                            </div>
                            <div class="stat-card members">
                                <div class="stat-value">25</div>
                                <div class="stat-label">Total Members</div>
                            </div>
                            <div class="stat-card income">
                                <div class="stat-value">₹2.1L</div>
                                <div class="stat-label">Monthly Income</div>
                            </div>
                        </div>
                        
                        <div class="chart-area">
                            <div class="chart-bars">
                                <div class="chart-bar"></div>
                                <div class="chart-bar"></div>
                                <div class="chart-bar"></div>
                                <div class="chart-bar"></div>
                                <div class="chart-bar"></div>
                                <div class="chart-bar"></div>
                                <div class="chart-bar"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="stats">
        <div class="container">
            <div class="stats-grid">
                <div class="stat-item reveal">
                    <h3>10+</h3>
                    <p>Societies Managed</p>
                </div>
                <div class="stat-item reveal">
                    <h3>100+</h3>
                    <p>Active Members</p>
                </div>
                <div class="stat-item reveal">
                    <h3>₹50L+</h3>
                    <p>Payments Processed</p>
                </div>
                <div class="stat-item reveal">
                    <h3>99.9%</h3>
                    <p>Uptime Guaranteed</p>
                </div>
            </div>
        </div>
    </section>

    <section class="features" id="features">
        <div class="container">
            <div class="section-header reveal">
                <h2>Complete Society Management Solution</h2>
                <p>Everything you need to run your cooperative housing society efficiently and transparently</p>
            </div>
            <div class="features-grid">
                <div class="feature-card reveal">
                    <div class="feature-icon">💰</div>
                    <h3>Payment Management</h3>
                    <p>Track maintenance payments, generate receipts, and monitor due amounts with automated reminders and penalty calculations.</p>
                </div>
                <div class="feature-card reveal">
                    <div class="feature-icon">👥</div>
                    <h3>Member Management</h3>
                    <p>Maintain comprehensive member profiles, track ownership details, and manage member communications efficiently.</p>
                </div>
                <div class="feature-card reveal">
                    <div class="feature-icon">📊</div>
                    <h3>Expense Tracking</h3>
                    <p>Monitor society expenses, categorize costs, and generate detailed financial reports with visual analytics.</p>
                </div>
                <div class="feature-card reveal">
                    <div class="feature-icon">🔧</div>
                    <h3>Maintenance Requests</h3>
                    <p>Handle shop maintenance and ownership maintenance requests with priority tracking and status updates.</p>
                </div>
                <div class="feature-card reveal">
                    <div class="feature-icon">📱</div>
                    <h3>Mobile Application</h3>
                    <p>Dedicated mobile app for society members to make payments, submit requests, and stay updated with society activities.</p>
                </div>
                <div class="feature-card reveal">
                    <div class="feature-icon">📈</div>
                    <h3>Advanced Analytics</h3>
                    <p>Comprehensive reports and analytics to help committee members make informed decisions about society operations.</p>
                </div>
            </div>
        </div>
    </section>

<%--    <section class="building-showcase" id="buildings">
        <div class="container">
            <div class="section-header reveal">
                <h2>Trusted by Leading Societies</h2>
                <p>Modern housing societies across the region rely on our platform</p>
            </div>
            <div class="building-grid">
                <div class="building-card reveal">
                    <div class="building-placeholder">🏢</div>
                    <div class="building-placeholder-text">
                        <h4>Premium Residences</h4>
                        <p>125 units • Full digital management</p>
                    </div>
                </div>
                <div class="building-card reveal">
                    <div class="building-placeholder">🏠</div>
                    <div class="building-placeholder-text">
                        <h4>Skyline Towers</h4>
                        <p>200+ units • Advanced security</p>
                    </div>
                </div>
                <div class="building-card reveal">
                    <div class="building-placeholder">🏘️</div>
                    <div class="building-placeholder-text">
                        <h4>Green Valley Society</h4>
                        <p>80 units • Eco-friendly</p>
                    </div>
                </div>
            </div>
        </div>
    </section>--%>

    <section class="mobile-app" id="mobile">
        <div class="container">
            <div class="app-content">
                <div class="app-text reveal-left">
                    <h2>Mobile App for Society Members</h2>
                    <p>Give your society members the convenience of managing everything from their smartphones</p>
                    
                    <ul class="app-features">
                        <li class="reveal-left">Make maintenance payments securely</li>
                        <li class="reveal-left">View payment history and receipts</li>
                        <li class="reveal-left">Submit maintenance requests</li>
                        <li class="reveal-left">Receive important society notifications</li>
                        <li class="reveal-left">Access society documents and notices</li>
                        <li class="reveal-left">Chat with society management</li>
                    </ul>
                    
                    <form runat="server">

                    <asp:Button ID="btnDownload" runat="server" Text="  📱 Download App"
    OnClick="btnDownload_Click" CssClass="btn btn-primary" />
                    </form>


                </div>
                <div class="app-visual reveal-right">
                    <div class="phone-mockup">
                        <div class="icon">📱</div>
                        <h3>Society App</h3>
                        <p>Available for iOS & Android</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="cta-section">
        <div class="container">
            <div class="cta-content reveal">
                <h2>Ready to Transform Your Society Management?</h2>
                <p>Join hundreds of societies already using our platform to streamline their operations</p>
                <a href="login1.aspx" class="btn-primary">Start Your Free Trial</a>
            </div>
        </div>
    </section>

    <footer id="contact">
        <div class="container">
            <div class="footer-content">
                <div class="footer-section">
                    <h3>VengurlaTech</h3>
                    <p>Modern society management system designed for cooperative housing societies.</p>
                </div>
                <div class="footer-section">
                    <h3>Quick Links</h3>
                    <a href="#features">Features</a>
                    <a href="#buildings">Showcase</a>
                    <a href="#mobile">Mobile App</a>
                    <a href="#">Terms and Conditions</a>
                    <a href="#">Login Portal</a>
                </div>
                <div class="footer-section">
                    <h3>Contact Us</h3>
                    <p>VengurlaTech Pvt Ltd</p>
                    <p>Vengurla, Maharashtra</p>
                    <p>support@vengurlatech.com</p>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2024 VengurlaTech Pvt Ltd. All rights reserved.</p>
            </div>
        </div>
    </footer>

    <script>
        // Create floating particles
        function createParticles() {
            const particlesContainer = document.getElementById('particles');
            const particleCount = 50;

            for (let i = 0; i < particleCount; i++) {
                const particle = document.createElement('div');
                particle.className = 'particle';
                particle.style.left = Math.random() * 100 + '%';
                particle.style.animationDelay = Math.random() * 15 + 's';
                particle.style.animationDuration = (Math.random() * 10 + 10) + 's';
                particlesContainer.appendChild(particle);
            }
        }

        createParticles();

        // Smooth scrolling with offset for fixed header
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const targetId = this.getAttribute('href');
                if (targetId === '#') return;

                const target = document.querySelector(targetId);
                if (target) {
                    const headerHeight = document.querySelector('header').offsetHeight;
                    const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - headerHeight;

                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });

                    navLinks.classList.remove('active');
                    mobileToggle.classList.remove('active');
                }
            });
        });

        // Mobile menu toggle
        const mobileToggle = document.querySelector('.mobile-menu-toggle');
        const navLinks = document.querySelector('.nav-links');

        if (mobileToggle && navLinks) {
            mobileToggle.addEventListener('click', function () {
                navLinks.classList.toggle('active');
                this.classList.toggle('active');
            });
        }

        // Header scroll effect
        window.addEventListener('scroll', function () {
            const header = document.querySelector('header');
            const currentScroll = window.pageYOffset;

            if (currentScroll > 100) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        });

        // Scroll reveal animation
        const revealElements = document.querySelectorAll('.reveal, .reveal-left, .reveal-right, .stat-item, .section-header, .feature-card, .building-card, .app-text, .app-visual, .app-features li, .cta-content');

        const revealObserver = new IntersectionObserver((entries) => {
            entries.forEach((entry, index) => {
                if (entry.isIntersecting) {
                    setTimeout(() => {
                        entry.target.classList.add('visible');
                    }, index * 100);
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        revealElements.forEach(element => {
            revealObserver.observe(element);
        });

        // Counter animation
        function animateCounter(element, target, duration = 2000) {
            const start = 0;
            const startTime = performance.now();

            function update(currentTime) {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);

                const current = Math.floor(progress * target);
                const text = element.textContent;
                const suffix = text.includes('+') ? '+' : (text.includes('%') ? '%' : '');
                const prefix = text.includes('₹') ? '₹' : '';
                const middle = text.includes('L') ? 'L' : (text.includes('k') ? 'k' : '');

                if (target >= 100) {
                    element.textContent = prefix + current + middle + suffix;
                } else {
                    element.textContent = prefix + current + suffix;
                }

                if (progress < 1) {
                    requestAnimationFrame(update);
                } else {
                    element.textContent = text;
                }
            }

            requestAnimationFrame(update);
        }

        // Animate counters when visible
        const statObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const h3 = entry.target.querySelector('h3');
                    const text = h3.textContent;
                    const number = parseInt(text.replace(/[^\d]/g, ''));

                    if (number > 0) {
                        animateCounter(h3, number);
                    }

                    statObserver.unobserve(entry.target);
                }
            });
        }, { threshold: 0.5 });

        document.querySelectorAll('.stat-item').forEach(stat => {
            statObserver.observe(stat);
        });

        // Parallax effect for hero section
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            const heroText = document.querySelector('.hero-text');
            const heroVisual = document.querySelector('.hero-visual');

            if (heroText && scrolled < window.innerHeight) {
                heroText.style.transform = `translateY(${scrolled * 0.3}px)`;
                if (heroVisual) {
                    heroVisual.style.transform = `translateY(${scrolled * 0.2}px)`;
                }
            }
        });

        // Smooth reveal for app features list items
        const featuresList = document.querySelectorAll('.app-features li');
        featuresList.forEach((item, index) => {
            item.style.transitionDelay = `${index * 0.1}s`;
        });

        // Add mouse move parallax effect for floating shapes
        document.addEventListener('mousemove', (e) => {
            const shapes = document.querySelectorAll('.shape');
            const mouseX = e.clientX / window.innerWidth;
            const mouseY = e.clientY / window.innerHeight;

            shapes.forEach((shape, index) => {
                const speed = (index + 1) * 0.5;
                const x = (mouseX - 0.5) * speed * 50;
                const y = (mouseY - 0.5) * speed * 50;

                shape.style.transform = `translate(${x}px, ${y}px)`;
            });
        });

        // Add cursor trail effect
        let lastX = 0;
        let lastY = 0;
        let isMoving = false;

        document.addEventListener('mousemove', (e) => {
            if (!isMoving) {
                isMoving = true;
                lastX = e.clientX;
                lastY = e.clientY;

                setTimeout(() => {
                    isMoving = false;
                }, 50);
            }
        });

        // Add scroll progress indicator
        const scrollProgress = document.createElement('div');
        scrollProgress.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 0%;
            height: 3px;
            background: linear-gradient(90deg, #D40000, #ff4444);
            z-index: 9999;
            transition: width 0.1s ease;
        `;
        document.body.appendChild(scrollProgress);

        window.addEventListener('scroll', () => {
            const windowHeight = window.innerHeight;
            const documentHeight = document.documentElement.scrollHeight;
            const scrollTop = window.pageYOffset;
            const scrollPercent = (scrollTop / (documentHeight - windowHeight)) * 100;
            scrollProgress.style.width = scrollPercent + '%';
        });

        // Add interactive hover effect on cards - SMOOTH VERSION
        document.querySelectorAll('.feature-card, .stat-card, .building-card').forEach(card => {
            let isHovering = false;

            card.addEventListener('mouseenter', () => {
                isHovering = true;
            });

            card.addEventListener('mouseleave', () => {
                isHovering = false;
                card.style.transform = '';
            });

            card.addEventListener('mousemove', (e) => {
                if (!isHovering) return;

                const rect = card.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;

                const centerX = rect.width / 2;
                const centerY = rect.height / 2;

                // Reduced rotation values for smoother effect
                const rotateX = ((y - centerY) / centerY) * 3; // Reduced from 10 to 3
                const rotateY = ((centerX - x) / centerX) * 3; // Reduced from 10 to 3

                card.style.transition = 'transform 0.1s ease-out';
                card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-8px) scale(1.02)`;
            });
        });
    </script>
</body>
</html>
