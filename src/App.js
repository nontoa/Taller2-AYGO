import logo from './logo-eci.png';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <br></br>
        <br></br>
        <p>
          Taller 2 AYGO - Nicolás Nontoa
        </p>
        <a
          className="App-link"
          href="https://github.com/nontoa/Taller2-AYGO"
          target="_blank"
          rel="noopener noreferrer"
        >
          GitHub Repository
        </a>
      </header>
    </div>
  );
}

export default App;
