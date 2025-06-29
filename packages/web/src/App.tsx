import { useState } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Panhandler</h1>
        <p>AI Agent Orchestration System</p>
      </header>

      <main>
        <div className="card">
          <button onClick={() => setCount(count => count + 1)}>count is {count}</button>
          <p>Autonomous software development with transparent cost tracking</p>
        </div>
      </main>
    </div>
  );
}

export default App;
